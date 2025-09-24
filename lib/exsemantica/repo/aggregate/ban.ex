defmodule Exsemantica.Repo.Aggregate.Ban do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aggregate_bans" do
    field(:expire, :utc_datetime)
    field(:reason, :string, default: "No reason given")

    belongs_to(:aggregate, Exsemantica.Repo.Aggregate, foreign_key: :aggregate_id)
    belongs_to(:moderator, Exsemantica.Repo.User, foreign_key: :moderator_id)
    belongs_to(:user, Exsemantica.Repo.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:aggregate, :moderator, :user, :expire, :reason])
    |> validate_required([:aggregate, :moderator, :user, :reason])
    |> validate_length(:reason, min: 1, max: 255)
    |> unique_constraint(:user_id)
  end
end
