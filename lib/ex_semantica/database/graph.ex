# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule ExSemantica.Database.Graph do
  @moduledoc """
  Stores a local shard of the social network's digraph connections. A shard
  holds 128 128-bit bitstrings, useful for SIMD engine support.

  TODO: A PubSub that notifies all OTP nodes of a change in the digraph.
  """
  use Agent
  use Bitwise

  @all_ones bnot(bsl(1, 128))

  @spec start_link(list) :: {:error, any} | {:ok, pid}
  def start_link([graph_data, name: name]) when map_size(graph_data) === 128 do
    Agent.start_link(fn -> graph_data end, name: name)
  end

  def start_link([graph_data]) when map_size(graph_data) === 128 do
    Agent.start_link(fn -> graph_data end)
  end

  @spec new_blank_graph :: map
  @doc """
  Initializes a new blank graph. Should be passed to start_link/1.
  """
  def new_blank_graph do
    0..127 |> Map.new(fn num -> {num, 0} end)
  end

  @spec get_vertex(atom | pid | {atom, any} | {:via, atom, any}, any) :: [non_neg_integer]
  @doc """
  Gets a vertex's neighbors from the graph.
  """
  def get_vertex(name, vertex) do
    Agent.get(name, & &1)
    |> get_in([vertex])
    |> extract_connections()
  end

  @spec put_vertex(atom | pid | {atom, any} | {:via, atom, any}, any, :add | :del, any) :: :ok
  @doc """
  Modifies a vertex's neighbors in the graph.

  - `:add`: Adds the vertex association
  - `:del`: Deletes the vertex association
  """
  def put_vertex(name, vertex, :add, neighbor) do
    Agent.update(
      name,
      fn graph_data ->
        graph_data
        |> update_in([vertex], fn modifiable -> modifiable |> bor(bsl(1, neighbor)) end)
      end
    )
  end

  def put_vertex(name, vertex, :del, neighbor) do
    Agent.update(
      name,
      fn graph_data ->
        graph_data
        |> update_in([vertex], fn modifiable ->
          modifiable |> band(bxor(@all_ones, bsl(1, neighbor)))
        end)
      end
    )
  end

  # TODO: Multiple vertices should be updated in one function

  @doc """
  Dumps the graph's data as a map.
  """
  def dump_graph(name) do
    Agent.get(name, & &1)
  end

  defp extract_connections(_extractable, extracted, 128), do: extracted

  defp extract_connections(extractable, extracted, left) do
    oper = bsl(1, left)

    extract_connections(
      extractable,
      case band(extractable, oper) do
        0 -> extracted
        _pass -> [left | extracted]
      end,
      left + 1
    )
  end

  defp extract_connections(extractable), do: extract_connections(extractable, [], 0)
end
