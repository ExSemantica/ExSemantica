# >>> Community Plug
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
defmodule Exsemantica.Community do
  @moduledoc """
  Community Plug

  API actions related to communities
  """
  @page_items_limit 25

  use Plug.Builder
  import Exsemantica.JSON, only: [send_json: 2]

  def call(conn, _opts) do
    t0 = DateTime.utc_now()

    conn = conn |> fetch_query_params()
    handle = conn.path_params["handle"]

    page =
      case Integer.parse(conn.query_params["page"] || "") do
        {number, ""} when number > 0 -> number
        _trash -> nil
      end
    IO.inspect conn.path_params["handle"]
    task =
      if is_nil(page) do
        Exsemantica.Tasks.CommunityInfo.async_read(handle, nil)
      else
        Exsemantica.Tasks.CommunityInfo.async_read(
          handle,
          {page * @page_items_limit, @page_items_limit}
        )
      end

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
            detail: "Community does not exist"
          }
        )

      {:ok, community} when is_nil(page) ->
        t1 = DateTime.utc_now()

        conn
        |> send_json(
          code: 200,
          json: %{
            ok: true,
            time: DateTime.diff(t1, t0, :millisecond),
            info: %{community: community.name, description: community.description}
          }
        )

      {:ok, community} ->
        t1 = DateTime.utc_now()

        conn
        |> send_json(
          code: 200,
          json: %{
            ok: true,
            time: DateTime.diff(t1, t0, :millisecond),
            info: %{
              community: community.name,
              description: community.description,
              threads: community.threads |> Enum.map(fn a -> %{id: a.id, author: a.user.name, title: a.title} end)
            }
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
            detail: "Username is not valid"
          }
        )
    end
  end
end
