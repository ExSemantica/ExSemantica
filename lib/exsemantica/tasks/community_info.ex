# >>> Tasks: Community Info
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
defmodule Exsemantica.Tasks.CommunityInfo do
  @moduledoc """
  Handles a community structure from SQL
  """
  import Ecto.Query

  @doc """
  Reads a user structure by using a name
  """
  def async_read(community, offset, count) do
    Task.async(fn ->
      case Exsemantica.Handle128.convert_to(community) do
        {:ok, name} ->
          query =
            from(c in Exsemantica.Repo.Community,
              join: t in assoc(c, :threads),
              order_by: [desc: t.id],
              where: c.name == ^name and t.id <= ^offset,
              limit: ^count,
              preload: [threads: t]
            )

          {:ok, Exsemantica.Repo.all(query)}

        error ->
          error
      end
    end)
  end
end
