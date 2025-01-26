defmodule Exsemantica.Repo.Migrations.CreateInviteCodes do
  use Ecto.Migration

  def change do
    create table(:invite_codes) do
      add :code, :binary, null: false
      add :is_valid, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
