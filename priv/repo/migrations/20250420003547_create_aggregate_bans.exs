defmodule Exsemantica.Repo.Migrations.CreateAggregateBans do
  use Ecto.Migration

  def change do
    create table(:aggregate_bans) do
      add :aggregate_id, :id, null: false
      add :moderator_id, :id, null: false
      add :user_id, :id, null: false
      add :expire, :utc_datetime
      add :reason, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:aggregate_bans, [:aggregate_id])
    create index(:aggregate_bans, [:moderator_id])
    create index(:aggregate_bans, [:user_id])
  end
end
