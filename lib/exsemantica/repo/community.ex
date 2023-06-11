# >>> Schema - Community
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
defmodule Exsemantica.Repo.Community do
  @moduledoc """
  A schema that represents communities
  """
  use Ecto.Schema

  schema "communities" do
    # The Handle128 of the community
    field :name, :string

    # A future-proof attributes map of booleans
    field :attributes, {:map, :boolean}

    # What subscribers do we have?
    many_to_many :subscribers, Exsemantica.Repo.User, join_through: "users_subscriptions"

    # What moderators do we have?
    many_to_many :moderators, Exsemantica.Repo.User, join_through: "moderators_communities"

    # We have many content posts
    has_many :threads, Exsemantica.Repo.Post
    
    timestamps()
  end
end
