# >>> Schema - Post
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
defmodule Exsemantica.Repo.Post do
  use Ecto.Schema

  schema "posts" do
    # A future-proof attributes map of booleans
    field :attributes, {:map, :boolean}

    # Title
    field :title, :string

    # Text
    field :content, :string

    # Who posted this?
    belongs_to :user, Exsemantica.Repo.User

    # Where was this posted?
    belongs_to :community, Exsemantica.Repo.Community

    # We have comments
    has_many :comments, Exsemantica.Repo.Comment
  end
end
