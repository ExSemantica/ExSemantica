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
defmodule ExSemantica.Api.Router do
  @moduledoc """
  Root endpoint router for API access. Forwards to other local endpoints.
  """
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  @cached_ping Jason.encode!(%{status: :ok})
  @cached_badrequest Jason.encode!(%{status: :bad_request})

  @doc """
  Cached /ping response
  """
  def cached_ping, do: @cached_ping

  @doc """
  Cached catchall response for a bad request
  """
  def cached_badrequest, do: @cached_badrequest

  get "/ping" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, @cached_ping)
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, @cached_badrequest)
  end
end
