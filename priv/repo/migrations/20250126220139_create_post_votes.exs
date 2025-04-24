defmodule Exsemantica.Repo.Migrations.CreatePostVotes do
  use Ecto.Migration

  def change do
    create table(:post_votes) do
      add :is_downvote, :boolean, null: false
      add :post_id, :id, null: false
      add :user_id, :id, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:post_votes, [:user_id])
    create index(:post_votes, [:post_id])
  end
end
