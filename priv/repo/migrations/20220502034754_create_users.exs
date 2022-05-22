defmodule Exsemantica.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :timestamp, :utc_datetime
      add :handle, :string
      add :privmask, :binary
      add :biography, :string

      timestamps()
    end

    create unique_index(:users, [:handle])
  end
end
