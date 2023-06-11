defmodule Exsemantica.Repo.Migrations.Initialize do
  use Ecto.Migration

  def change do
    # =========================================================================
    # CREATE ALL REGULAR TABLES
    # =========================================================================

    # Create a User table =====================================================
    create table(:users) do
      add :name, :string, size: 16
      add :biography, :string, size: 256
      add :password_hash, :binary
      add :attributes, :map

      timestamps()
    end
    # Create a Community table ================================================
    create table(:communities) do
      add :name, :string, size: 16
      add :attributes, :map

      timestamps()
    end
    # Create a Post table =====================================================
    create table(:posts) do
      add :title, :string, size: 64
      add :content, :string, size: 4096
      add :attributes, :map

      add :user_id, references(:users), null: false
      add :community_id, references(:communities), null: false

      timestamps()
    end
    # Create a Comment table ==================================================
    create table(:comments) do
      add :content, :string, size: 256
      add :attributes, :map

      add :parent_id, references(:comments)
      add :post_id, references(:posts), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end

    # =========================================================================
    # CREATE ALL JOINS
    # =========================================================================

    # Create a User-Subscription join =========================================
    create table(:users_subscriptions) do
      add :subscriber_id, references(:users)
      add :subscription_id, references(:communities)
    end
    create unique_index(:users_subscriptions, [:subscriber_id, :subscription_id])
    # Create a Moderator-Community join =======================================
    create table(:moderators_communities) do
      add :moderator_id, references(:users)
      add :community_id, references(:communities)
    end
    create unique_index(:moderators_communities, [:moderator_id, :community_id])
  end
end
