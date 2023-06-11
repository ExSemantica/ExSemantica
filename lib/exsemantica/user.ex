# >>> User Plug
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
defmodule Exsemantica.User do
  @moduledoc """
  User Plug

  API actions related to users
  """
  use Plug.Builder
  import Exsemantica.JSON, only: [send_json: 2]

  def call(conn, _opts) do
    t0 = DateTime.utc_now()

    handle = conn.path_params["handle"]

    task = Exsemantica.Tasks.UserInfo.async_read(handle)

    case task |> Task.await() do
      {:ok, nil} ->
        t1 = DateTime.utc_now()

        conn
        |> send_json(
          code: 404,
          json: %{
            ok: false,
            e: :not_found,
            time: DateTime.diff(t1, t0, :millisecond),
            detail: "User does not exist",
          }
        )

      {:ok, user} ->
        t1 = DateTime.utc_now()

        conn
        |> send_json(
          code: 200,
          json: %{
            ok: true,
            time: DateTime.diff(t1, t0, :millisecond),
            info: %{user: user.name, biography: user.biography}
          }
        )

      {:error, _error} ->
        t1 = DateTime.utc_now()

        conn
        |> send_json(
          code: 400,
          json: %{
            ok: false,
            e: :bad_request,
            time: DateTime.diff(t1, t0, :millisecond),
            detail: "Username is not valid",
          }
        )
    end
  end
end
