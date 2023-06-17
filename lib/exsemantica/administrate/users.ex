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
  import Ecto.Query

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

  def set_community_moderation(user, community_id, moderator?) do
    if moderator? do
      Exsemantica.Repo.insert("moderators_communities", moderator_id: user.id, community_id: community_id)
    else
      from("moderators_communities", where: [moderator_id: ^user.id, community_id: ^community_id])
      |> Exsemantica.Repo.delete_all()
    end
  end

  def set_post_vote(user, post_id, upvote: upvote, downvote: downvote) do
    if upvote and downvote do
      {:error, :einval}
    else
      cond do
        upvote ->
          user
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:downvoted_posts, %{downvoter_id: user.id, post_id: post_id})
          |> Ecto.Changeset.cast_assoc(:downvoted_posts)

          user
          |> Exsemantica.Repo.preload(:upvoted_posts)
          |> Ecto.Changeset.cast(%{upvoter_id: user.id, post_id: post_id})
          |> Ecto.Changeset.cast_assoc(:upvoted_posts)
        downvote ->
          from("posts_upvotes", where: [post_id: ^post_id, upvoter_id: ^user.id])
          |> Exsemantica.Repo.delete_all()

          Exsemantica.Repo.insert(:posts_downvotes, post_id: post_id, downvoter_id: user.id)

        true ->
          from("posts_upvotes", where: [post_id: ^post_id, upvoter_id: ^user.id])
          |> Exsemantica.Repo.delete_all()

          from("posts_downvotes", where: [post_id: ^post_id, downvoter_id: ^user.id])
          |> Exsemantica.Repo.delete_all()
      end
    end
  end
end
