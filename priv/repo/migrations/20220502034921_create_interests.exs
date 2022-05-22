defmodule Exsemantica.Repo.Migrations.CreateInterests do
  use Ecto.Migration

  def change do
    create table(:interests) do
      add :timestamp, :utc_datetime
      add :handle, :string
      add :title, :string
      add :content, :string
      add :posted_by, :integer

      timestamps()
    end

    create unique_index(:interests, [:handle])
  end
end
