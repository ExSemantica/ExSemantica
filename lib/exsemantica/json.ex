# >>> JSON utilities
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
defmodule Exsemantica.JSON do
  @moduledoc """
  JSON Plug utilities
  """
  import Plug.Conn

  @doc """
  Inserts the 'JSON' MIME type into the response

  This should be called before the main Plug does anything

  ```elixir
  import Exsemantica.JSON, only: [inject_prelude: 2]
  plug :inject_prelude
  # do some other stuff after the prelude
  ```
  """
  def inject_prelude(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
  end

  def send_json(conn, [code: code, json: json]) do
    {:ok, text_json} = Jason.encode(json)

    conn
    |> send_resp(code, text_json)
  end
end
