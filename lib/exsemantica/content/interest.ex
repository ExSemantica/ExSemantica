defmodule Exsemantica.Content.Interest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "interests" do
    field :content, :string
    field :handle, :string
    field :related_to, {:array, :integer}
    field :timestamp, :utc_datetime
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:timestamp, :handle, :title, :content, :related_to])
    |> validate_required([:timestamp, :handle, :title, :content, :related_to])
    |> unique_constraint(:handle)
  end
end
