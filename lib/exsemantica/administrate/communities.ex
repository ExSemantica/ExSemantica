# >>> Insert, edit, remove communities
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
defmodule Exsemantica.Administrate.Communities do
  def insert(name, description) do
    case Exsemantica.Handle128.convert_to(name) do
      {:ok, handle} ->
        {:ok,
         Exsemantica.Repo.insert(%Exsemantica.Repo.Community{
           name: handle,
           description: description
         })}

      error ->
        error
    end
  end

  def post_into(community, user, title, content) do
    %Exsemantica.Repo.Post{user: user, title: title, content: content}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:community, community)
    |> Exsemantica.Repo.insert()
  end
end
