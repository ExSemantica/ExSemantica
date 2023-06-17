# >>> Schema - Comment
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
defmodule Exsemantica.Repo.Comment do
  @moduledoc """
  A schema that represents comments inside a post
  """
  use Ecto.Schema

  schema "comments" do
    # A future-proof attributes map of booleans
    field(:attributes, {:map, :boolean})

    # Text
    field(:content, :string)

    # Who posted this?
    belongs_to(:user, Exsemantica.Repo.User)

    # Where we belong
    belongs_to(:post, Exsemantica.Repo.Post)

    # Comment parent/children
    belongs_to(:parent, Exsemantica.Repo.Comment)
    has_many(:children, Exsemantica.Repo.Comment)

    # Upvotes and downvotes
    many_to_many(:votes, Exsemantica.Repo.User, join_through: "comments_votes")

    timestamps()
  end
end
