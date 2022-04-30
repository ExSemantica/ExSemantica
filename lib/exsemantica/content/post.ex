defmodule Exsemantica.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :content, :binary
    field :handle, :binary
    field :posted_by, :integer
    field :timestamp, :utc_datetime
    field :title, :binary

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:timestamp, :handle, :title, :content, :posted_by])
    |> validate_required([:timestamp, :handle, :title, :content, :posted_by])
    |> unique_constraint(:handle)
  end
end
