defmodule Exsemantica.Repo.Aggregate do
  @moduledoc """
  Represents a collection of `Exsemantica.Repo.Post`s
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "aggregates" do
    field(:hidden?, :boolean, default: false)
    field(:hidden_reason, :string, default: "No reason given")
    field(:name, :string)
    field(:description, :string)
    field(:description_modified, :utc_datetime)
    field(:tags, {:array, :string})

    has_many(:posts, Exsemantica.Repo.Post)
    has_many(:bans, Exsemantica.Repo.Aggregate.Ban)
    many_to_many(:subscriptions, Exsemantica.Repo.Aggregate, join_through: "subscriptions_users")
    many_to_many(:moderators, Exsemantica.Repo.User, join_through: "moderators_aggregates")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(aggregate, attrs) do
    aggregate
    |> cast(attrs, [
      :hidden?,
      :hidden_reason,
      :name,
      :description,
      :description_modified,
      :posts,
      :bans,
      :tags,
      :subscriptions,
      :moderators
    ])
    |> validate_required([
      :hidden?,
      :hidden_reason,
      :name,
      :description,
      :description_modified,
      :posts,
      :bans,
      :subscriptions,
      :moderators
    ])
    |> validate_length(:name, min: 1, max: 31)
    |> validate_length(:hidden_reason, min: 1, max: 255)
    |> validate_length(:description, min: 1, max: 1023)
    |> validate_length(:tags, min: 0, max: 32)
    |> validate_exclusion(:name, ~w(Services))
    |> validate_format(:name, ~r/^[0-9A-Za-z_]+$/)
    |> unique_constraint(:name)
  end
end
