# >>> Main Plug Router
# Copyright 2023 Roland Metivier <metivier.roland@chlorophyt.us>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.Router do
  @moduledoc """
  Plug Router

  This handles API requests

  ## Goals
  This probably won't completely comply with ActivityPub because this is just
  going to be a link aggregator.
  """
  use Plug.Router
  import Exsemantica.JSON, only: [inject_prelude: 2, send_json: 2]

  plug(Plug.Logger)
  plug(:inject_prelude)
  plug(:match)
  plug(:dispatch)

  # We forward these, `handle` is a Handle128
  # This is for viewing user information
  forward("/user/:handle", to: Exsemantica.User)
  # This is for viewing community information
  forward("/community/:handle", to: Exsemantica.Community)

  # We 501 here, there's nothing this catch-all endpoint can do
  match _ do
    conn
    |> send_json(
      code: 501,
      json: %{
        ok: false,
        e: :not_implemented,
        detail: "This API endpoint does not exist"
      }
    )
  end
end
