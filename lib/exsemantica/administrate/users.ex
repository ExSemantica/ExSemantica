# >>> Insert, edit, remove users
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
defmodule Exsemantica.Administrate.Users do
  @moduledoc """
  Various functions for manipulating users
  """

  @doc """
  Inserts a new regular user
  """
  def insert(name, password, biography) do
    case Exsemantica.Handle128.convert_to(name) do
      {:ok, handle} ->
        {:ok,
         Exsemantica.Repo.insert(%Exsemantica.Repo.User{
           name: handle,
           password_hash: Argon2.hash_pwd_salt(password),
           biography: biography
         })}

      error ->
        error
    end
  end

  @doc """
  Sets a user's moderation flag on a community

  `moderator?` is whether the user should be a moderator or not
  """
  def set_moderator_for_community(user, community, moderator?) do
    if moderator? do
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:moderating, community.id)
      |> Exsemantica.Repo.insert()
    else
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.get_assoc(:moderating, community.id)
      |> Exsemantica.Repo.delete() 
    end
  end

  @doc """
  Adds or removes a vote on a post acting as a user

  `vote_coefficient`: -1 = downvote, 0 = abstain, 1 = upvote
  """
  def set_post_vote(user, post, vote_coefficient) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:voted_posts, %{post_id: post.id, vote_coefficient: vote_coefficient})
    |> Exsemantica.Repo.insert_or_update()
  end

  @doc """
  Adds or removes a vote on a comment acting as a user

  `vote_coefficient`: -1 = downvote, 0 = abstain, 1 = upvote
  """
  def set_comment_vote(user, comment, vote_coefficient) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:voted_comments, %{comment_id: comment.id, vote_coefficient: vote_coefficient})
    |> Exsemantica.Repo.insert_or_update()
  end
end
