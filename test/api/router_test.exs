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
defmodule ExSemantica.Api.Router.Test do
  use ExUnit.Case
  use Plug.Test
  doctest ExSemantica.Api.Router
  @opts ExSemantica.Api.Router.init([])

  test "status check returns ok" do
    conn = conn(:get, "/ping")
    conn = conn |> ExSemantica.Api.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ExSemantica.Api.Router.cached_ping()
  end

  test "catchall check returns indication of invalid response" do
    conn = conn(:get, "/invalid")
    conn = conn |> ExSemantica.Api.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body == ExSemantica.Api.Router.cached_badrequest()
  end
end
