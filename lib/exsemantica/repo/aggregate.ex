defmodule Exsemantica.Repo.Aggregate do
  @moduledoc """
  Represents a collection of `Exsemantica.Repo.Post`s
  """
  use Ecto.Schema
  import Ecto.Changeset

  def max_name_length(), do: 31
  def max_description_length(), do: 511

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
    |> validate_length(:name, min: 1, max: max_name_length())
    |> validate_length(:hidden_reason, min: 1, max: 255)
    |> validate_length(:description, min: 1, max: max_description_length())
    |> validate_length(:tags, min: 0, max: 32)
    |> validate_exclusion(:name, ~w(Services))
    |> validate_format(
      :name,
      ~r/^[\x01-\x07\x08-\x09\x0b-\x0c\x03-\x1f\x21-\x2b\x2d-\x39\x3b-\xff]+$/
    )
    |> unique_constraint(:name)
  end
end
