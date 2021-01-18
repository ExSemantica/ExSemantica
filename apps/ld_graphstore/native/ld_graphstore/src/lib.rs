// Copyright 2020-2021 Roland Metivier
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};
use std::collections::HashMap;
use std::num::Wrapping;
use std::sync::mpsc::*;
use std::sync::{Arc, Barrier, RwLock, Weak};
use std::thread;

static IGNORE: u64 = 0x0000_0000_0000_0000;
static ROOTID: u64 = 0x0000_0000_0000_0001;
static ALLHOT: u64 = 0xFFFF_FFFF_FFFF_FFFF;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
        atom noval;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

enum TreeLockstepCommandEnum {
    // Get an object in all trees
    Get,
    // Put an object in all trees
    Put,
    // Delete an object in all trees
    Del,
    // Garbage collect all trees
    Gc,
}

#[derive(Clone)]
struct Tree {
    hint_idx: u64,
    children: HashMap<u64, __m256i>,
}

#[derive(NifStruct)]
#[module = "LdGraphstore.Native.QueryResponse"]
struct QueryResponse {
    parent: Option<u64>,
    child: Option<u64>,
    sibling: Option<u64>,
    this: u64,
    ticket: u64,
}

struct TreeLockstepCommand {
    etype: TreeLockstepCommandEnum,
    edata: u64,
    ticket: u64,
}

#[derive(Clone)]
struct TreeLockstep {
    fifo: Sender<QueryResponse>,
    tree: Tree,
}

struct TreeResource {
    lockstep: Vec<TreeLockstep>,
    receiver: Receiver<QueryResponse>,

    command: RwLock<Vec<Arc<TreeLockstepCommand>>>,

    ticket: Wrapping<u64>,
}

impl Tree {
    unsafe fn new() -> Tree {
        let mut tree = Tree {
            hint_idx: ROOTID,
            children: HashMap::new(),
        };
        tree.children.insert(
            1,
            _mm256_set_epi64x(
                IGNORE as i64, // Parent  (val[3])
                IGNORE as i64, // Child   (val[2])
                IGNORE as i64, // Sibling (val[1])
                ROOTID as i64, // Self    (val[0])
            ),
        );
        tree
    }
    fn wrap(val: u64) -> Option<u64> {
        if val == IGNORE {
            None
        } else {
            Some(val)
        }
    }
    unsafe fn unpacked_values(packed: __m256i) -> [u64; 4] {
        let mut extracted: [u64; 4] = [ALLHOT, ALLHOT, ALLHOT, ALLHOT];
        _mm256_maskstore_epi64(
            extracted.as_mut_ptr() as *mut i64,
            _mm256_set1_epi64x(ALLHOT as i64),
            packed,
        );
        extracted
    }
    unsafe fn get_parent(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[3])
    }
    unsafe fn get_child(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[2])
    }
    unsafe fn get_sibling(parent: __m256i) -> Option<u64> {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        Tree::wrap(relationships[1])
    }
    unsafe fn get_self(parent: __m256i) -> u64 {
        // Extract results
        let relationships: [u64; 4] = Tree::unpacked_values(parent);
        relationships[0]
    }
    unsafe fn construct(&mut self, idx: u64) -> u64 {
        assert_ne!(idx, 0);
        match Tree::get_child(self.children[&idx]).unwrap_or(IGNORE) {
            0x0000_0000_0000_0000_u64 => {
                // Construct a child
                self.hint_idx += 1;

                self.children.insert(
                    idx,
                    _mm256_or_si256(
                        self.children[&idx],
                        _mm256_set_epi64x(
                            IGNORE as i64,
                            self.hint_idx as i64,
                            IGNORE as i64,
                            IGNORE as i64,
                        ),
                    ),
                );
                self.children.insert(
                    self.hint_idx,
                    _mm256_set_epi64x(
                        idx as i64,
                        IGNORE as i64,
                        IGNORE as i64,
                        self.hint_idx as i64,
                    ),
                );
                self.hint_idx
            }
            _ => {
                // Construct a sibling
                let mut pivot = self.children[&idx];
                loop {
                    match Tree::get_sibling(pivot).unwrap_or(IGNORE) {
                        0x0000_0000_0000_0000_u64 => {
                            self.hint_idx += 1;
                            // NOTE: The parent of a sibling will be its last sibling
                            self.children.insert(
                                Tree::get_self(pivot),
                                _mm256_or_si256(
                                    pivot,
                                    _mm256_set_epi64x(
                                        IGNORE as i64,
                                        IGNORE as i64,
                                        self.hint_idx as i64,
                                        IGNORE as i64,
                                    ),
                                ),
                            );
                            // Finally insert the sibling
                            self.children.insert(
                                self.hint_idx,
                                _mm256_set_epi64x(
                                    Tree::get_self(pivot) as i64,
                                    IGNORE as i64,
                                    IGNORE as i64,
                                    self.hint_idx as i64,
                                ),
                            );
                            break;
                        }
                        next => {
                            pivot = self.children[&next];
                            continue;
                        }
                    }
                }
                self.hint_idx
            }
        }
    }
    unsafe fn collect(&mut self) {
        let zeroes = _mm256_setzero_si256();
        self.children.retain(|&k, &mut v| {
            // If parent is equal to zero then GC
            if let Some(_) = Tree::get_parent(_mm256_cmpeq_epi64(v, zeroes)) {
                k == ROOTID
            } else {
                true
            }
        });
    }
    unsafe fn remove(&mut self, idx: u64) {
        assert_ne!(idx, 0);
        assert_ne!(idx, 1);
        let zeroes = _mm256_setzero_si256();
        match Tree::unpacked_values(self.children[&idx]) {
            [obj, 0_u64, 0_u64, 0_u64] => {
                self.children.insert(obj, zeroes);
            }
            [obj, 0_u64, 0_u64, parent] => {
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
            [obj, sibling, 0_u64, parent] => {
                // Since parent(s) are zeroed, we will automatically GC it later
                let mut next = Tree::wrap(sibling);
                while let Some(next_unwrapped) = next {
                    next = Tree::get_sibling(self.children[&next_unwrapped]);
                    self.children.insert(next_unwrapped, zeroes);
                }
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
            [obj, sibling, child, parent] => {
                self.remove(sibling);
                self.remove(child);
                self.children.insert(obj, zeroes);
                self.children.insert(
                    parent,
                    _mm256_xor_si256(
                        self.children[&parent],
                        _mm256_set_epi64x(IGNORE as i64, IGNORE as i64, obj as i64, IGNORE as i64),
                    ),
                );
            }
        }
    }
}

impl TreeLockstep {
    fn new(fifo: &Sender<QueryResponse>) -> TreeLockstep {
        TreeLockstep {
            fifo: fifo.clone(),
            tree: unsafe { Tree::new() },
        }
    }
    fn step(&self, command: &Arc<TreeLockstepCommand>) {
        match command.etype {
            TreeLockstepCommandEnum::Get => {
                if self.tree.children.contains_key(&command.edata) {
                    let item = self.tree.children[&command.edata];
                    if IGNORE != unsafe { Tree::get_self(self.tree.children[&command.edata]) } {
                        let unpacked = Tree::unpacked_values(self.tree.children[&command.edata]);
                        self.fifo.send(QueryResponse {
                            ticket: command.ticket,
                            this: unpacked[0],
                            child: Some(unpacked[2]),
                            sibling: Some(unpacked[1]),
                            parent: Some(unpacked[3]),
                        });
                        return;
                    }
                }
                self.fifo.send(QueryResponse {
                    ticket: command.ticket,
                    this: IGNORE,
                    child: None,
                    sibling: None,
                    parent: None,
                });
            }
            TreeLockstepCommandEnum::Put => {
                if self.tree.children.contains_key(&command.edata) {
                    let item = self.tree.children[&command.edata];
                    if 0_u64 != unsafe { Tree::get_self(self.tree.children[&command.edata]) } {
                        let constructed = self.tree.construct(command.edata);
                        let unpacked = Tree::unpacked_values(self.tree.children[&constructed]);
                        self.fifo.send(QueryResponse {
                            ticket: command.ticket,
                            this: unpacked[0],
                            child: Some(unpacked[2]),
                            sibling: Some(unpacked[1]),
                            parent: Some(unpacked[3]),
                        });
                        return;
                    }
                }
                self.fifo.send(QueryResponse {
                    ticket: command.ticket,
                    this: IGNORE,
                    child: None,
                    sibling: None,
                    parent: None,
                });
            }
            TreeLockstepCommandEnum::Del => {
                if self.tree.children.contains_key(&command.edata) {
                    let item = self.tree.children[&command.edata];
                    if 0_u64 != unsafe { Tree::get_self(self.tree.children[&command.edata]) } {
                        self.tree.remove(command.edata);
                        self.fifo.send(QueryResponse {
                            ticket: command.ticket,
                            this: IGNORE,
                            child: None,
                            sibling: None,
                            parent: None,
                        });
                        return;
                    }
                }
                self.fifo.send(QueryResponse {
                    ticket: command.ticket,
                    this: IGNORE,
                    child: None,
                    sibling: None,
                    parent: None,
                });
            }
            TreeLockstepCommandEnum::Gc => {
                self.tree.collect();
                self.fifo.send(QueryResponse {
                    ticket: command.ticket,
                    this: IGNORE,
                    child: None,
                    sibling: None,
                    parent: None,
                });
            }
        }
    }
}

rustler::rustler_export_nifs! {
    "Elixir.LdGraphstore.Native",
    [
        ("dbasync_gc", 1, dbasync_gc),
        ("dbasync_get", 2, dbasync_get),
        ("dbasync_put", 2, dbasync_put),
        ("dbasync_del", 2, dbasync_del),
        ("dbasync_tick", 1, dbasync_tick),
        ("db_create", 1, db_create),
        ("db_test", 1, db_test),
    ],
    Some(on_load)
}

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource_struct_init!(TreeResource, env);
    true
}

fn db_create<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let lockstep: usize = args[0].decode()?;

    let (tx, rx) = channel();
    let command = RwLock::new(vec![]);

    let resource = ResourceArc::new(TreeResource {
        lockstep: vec![TreeLockstep::new(&tx); lockstep],
        receiver: rx,
        command: command,
        ticket: Wrapping(0_u64),
    });

    Ok((atoms::ok(), resource).encode(env))
}
// ============================================================================
//  You can not do message passing in NIFs. You can, however, be asynchronous.
// ============================================================================
fn dbasync_tick<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    {
        let queue = resource.command.write().expect("Can't get Write Access");
        if let Some(command) = queue.pop() {
            let command = Arc::new(command);
            for thread in resource.lockstep {
                thread::spawn(move || thread.step(&command));
            }
        }
    }
    Ok((atoms::ok()).encode(env))
}

fn dbasync_recv<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    Ok((atoms::ok(), {
        let responses = vec![];
        for response in resource.receiver.try_iter() {
            responses.push(response)
        }
        responses
    })
        .encode(env))
}

fn dbasync_gc<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    Ok((atoms::ok(), {
        let ticket = resource.ticket.0;
        let queue = resource.command.write().expect("Can't get Write Access");
        let arc = Arc::new(TreeLockstepCommand {
            etype: TreeLockstepCommandEnum::Gc,
            edata: IGNORE,
            ticket: ticket,
        });
        queue.push(arc);
        resource.ticket += Wrapping(1_u64);
        ticket
    })
        .encode(env))
}

fn dbasync_get<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let idx: u64 = args[1].decode()?;
    Ok((atoms::ok(), {
        let ticket = resource.ticket.0;
        let queue = resource.command.write().expect("Can't get Write Access");
        let arc = Arc::new(TreeLockstepCommand {
            etype: TreeLockstepCommandEnum::Get,
            edata: idx,
            ticket: ticket,
        });
        queue.push(arc);
        resource.ticket += Wrapping(1_u64);
        ticket
    })
        .encode(env))
}

fn dbasync_put<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let idx: u64 = args[1].decode()?;
    Ok((atoms::ok(), {
        let ticket = resource.ticket.0;
        let queue = resource.command.write().expect("Can't get Write Access");
        let arc = Arc::new(TreeLockstepCommand {
            etype: TreeLockstepCommandEnum::Put,
            edata: idx,
            ticket: ticket,
        });
        queue.push(arc);
        resource.ticket += Wrapping(1_u64);
        ticket
    })
        .encode(env))
}

fn dbasync_del<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<TreeResource> = args[0].decode()?;
    let idx: u64 = args[1].decode()?;
    Ok((atoms::ok(), {
        let ticket = resource.ticket.0;
        let queue = resource.command.write().expect("Can't get Write Access");
        let arc = Arc::new(TreeLockstepCommand {
            etype: TreeLockstepCommandEnum::Del,
            edata: idx,
            ticket: ticket,
        });
        queue.push(arc);
        resource.ticket += Wrapping(1_u64);
        ticket
    })
        .encode(env))
}

fn db_test<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    unsafe {
        let mut tree = Tree::new();

        println!("Logical testing...\r");
        assert_eq!(tree.construct(1_u64), 2);
        assert_eq!(tree.construct(2_u64), 3);
        assert_eq!(tree.construct(2_u64), 4);
        let stress: u64 = args[0].decode()?;
        let mut interval = 4_u64;
        println!("Stress testing... {:?}\r", stress);
        for _ in 0..stress {
            interval = tree.construct(4_u64);
        }
        println!(
            "Passed sibling construction/destruction without catching fire (at {})\r",
            interval
        );
        for _ in 0..stress {
            interval = tree.construct(interval);
        }
        println!(
            "Passed child-sibling construction without catching fire (at {})\r",
            interval
        );
        tree.remove(2_u64);
        println!("Passed removal of all elements\r");
        tree.collect();
        println!("GC all good\r");
    }
    Ok(atoms::ok().encode(env))
}
