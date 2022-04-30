defmodule Exsemantica.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :timestamp, :utc_datetime
      add :handle, :binary
      add :privmask, :binary

      timestamps()
    end

    create unique_index(:users, [:handle])
  end
end
