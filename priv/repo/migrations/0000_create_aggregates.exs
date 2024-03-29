defmodule Exsemantica.Repo.Migrations.CreateAggregates do
  use Ecto.Migration

  def change do
    create table(:aggregates) do
      add :name, :string
      add :description, :text

      timestamps()
    end

    create unique_index(:aggregates, [:name])
  end
end
