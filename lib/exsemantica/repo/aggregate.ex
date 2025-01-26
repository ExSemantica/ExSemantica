defmodule Exsemantica.Repo.Aggregate do
  @moduledoc """
  Represents a collection of `Exsemantica.Repo.Post`s
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "aggregates" do
    field(:hidden, :boolean, default: false)
    field(:name, :string)
    field(:description, :string)
    field(:tags, {:array, :string})

    has_many(:posts, Exsemantica.Repo.Post)
    many_to_many(:subscriptions, Exsemantica.Repo.Aggregate, join_through: "subscriptions_users")
    many_to_many(:moderators, Exsemantica.Repo.User, join_through: "moderators_aggregates")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(aggregate, attrs) do
    aggregate
    |> cast(attrs, [:name, :description, :posts, :subscriptions, :moderators])
    |> validate_required([:name, :description, :posts, :subscriptions, :moderators])
    |> validate_length(:name, min: 1, max: 31)
    |> validate_exclusion(:name, ~w(Services))
    |> validate_format(:name, ~r/^[0-9A-Za-z_]+$/)
    |> unique_constraint(:name)
  end
end
