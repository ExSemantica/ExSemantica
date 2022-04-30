defmodule Exsemantica.Content.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :handle, :binary
    field :privmask, :binary
    field :timestamp, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:timestamp, :handle, :privmask])
    |> validate_required([:timestamp, :handle, :privmask])
    |> unique_constraint(:handle)
  end
end
