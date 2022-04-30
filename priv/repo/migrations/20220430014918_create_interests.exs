defmodule Exsemantica.Repo.Migrations.CreateInterests do
  use Ecto.Migration

  def change do
    create table(:interests) do
      add :timestamp, :utc_datetime
      add :handle, :binary
      add :title, :binary
      add :content, :binary
      add :related_to, {:array, :integer}

      timestamps()
    end

    create unique_index(:interests, [:handle])
  end
end
