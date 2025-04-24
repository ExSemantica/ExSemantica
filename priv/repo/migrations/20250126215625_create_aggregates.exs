defmodule Exsemantica.Repo.Migrations.CreateAggregates do
  use Ecto.Migration

  def change do
    create table(:aggregates) do
      add :hidden?, :boolean, null: false
      add :hidden_reason, :string, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :description_modified, :utc_datetime, null: false
      add :posts, {:array, :id}
      add :tags, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:aggregates, [:name])
  end
end
