defmodule Exsemantica.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :hidden, :boolean, null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :contents, :text
      add :user_id, :id, null: false
      add :aggregate_id, :id, null: false
      add :votes, {:array, :id}
      add :comments, {:array, :id}
      add :tags, {:array, :string}

      timestamps(type: :utc_datetime)
    end
  end
end
