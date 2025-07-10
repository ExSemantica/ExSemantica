defmodule Exsemantica.Repo.User do
  @moduledoc """
  Users can post and make comments
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:hidden, :boolean, default: false)
    field(:username, :string)
    field(:extname, :string)
    field(:password, :string, redact: true)
    field(:biography, :string)
    field(:email, :string)

    field(:banned?, :boolean, default: false)
    field(:banned_expire, :utc_datetime)
    field(:banned_reason, :string, default: "No reason given")

    has_many(:posts, Exsemantica.Repo.Post, foreign_key: :user_id)
    has_many(:comments, Exsemantica.Repo.Comment, foreign_key: :user_id)

    has_many(:comment_votes, Exsemantica.Repo.Vote.Comment, foreign_key: :user_id)
    has_many(:post_votes, Exsemantica.Repo.Vote.Post, foreign_key: :user_id)

    many_to_many(:subscriptions, Exsemantica.Repo.Aggregate, join_through: "subscriptions_users")
    many_to_many(:aggregates, Exsemantica.Repo.Aggregate, join_through: "moderators_aggregates")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :extname,
      :biography,
      :email,
      :password,
      :subscriptions,
      :aggregates,
      :banned?,
      :banned_expire,
      :banned_reason
    ])
    |> validate_required([
      :username,
      :extname,
      :email,
      :password,
      :subscriptions,
      :aggregates
    ])
    |> validate_length(:username, min: 1, max: 15)
    |> validate_length(:extname, min: 1, max: 63)
    |> validate_length(:banned_reason, min: 1, max: 255)
    |> validate_length(:biography, min: 0, max: 1023)
    |> validate_exclusion(:username, ~w(Services))
    |> validate_format(:username, ~r/^[0-9A-Za-z_]+$/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
