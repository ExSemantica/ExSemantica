defmodule Exsemantica.Repo.Migrations.CreateCommentVotes do
  use Ecto.Migration

  def change do
    create table(:comment_votes) do
      add :is_downvote, :boolean, null: false
      add :comment_id, :id, null: false
      add :user_id, :id, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:comment_votes, [:comment_id])
    create index(:comment_votes, [:user_id])
  end
end
