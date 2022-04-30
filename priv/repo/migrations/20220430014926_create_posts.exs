defmodule Exsemantica.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :timestamp, :utc_datetime
      add :handle, :binary
      add :title, :binary
      add :content, :binary
      add :posted_by, :integer

      timestamps()
    end

    create unique_index(:posts, [:handle])
  end
end
