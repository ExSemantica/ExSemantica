# >>> Schema - User
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
defmodule Exsemantica.Repo.User do
  @moduledoc """
  A schema that represents users
  """

  use Ecto.Schema

  schema "users" do
    # The Handle128 of the user
    field(:name, :string)

    # The bio of the user
    field(:biography, :string)

    # The hashed passphrase of the user
    field(:password_hash, :binary, redact: true)

    # A future-proof attributes map of booleans
    field(:attributes, {:map, :boolean})

    # What subscribers do we have?
    many_to_many(:subscriptions, Exsemantica.Repo.Community, join_through: "users_subscriptions")

    # What are we moderating?
    many_to_many(:moderating, Exsemantica.Repo.Community, join_through: "moderators_communities")

    many_to_many(:voted_posts, Exsemantica.Repo.Post, join_through: "posts_votes")
    many_to_many(:voted_comments, Exsemantica.Repo.Comment, join_through: "comments_votes")

    timestamps()
  end
end
