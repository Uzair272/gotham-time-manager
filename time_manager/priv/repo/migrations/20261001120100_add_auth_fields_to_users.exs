defmodule TimeManager.Repo.Migrations.AddAuthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Never the real password: only its bcrypt hash
      add :password_hash, :string
      # Every user has one role; existing users become employees (id 1)
      add :role_id, references(:roles, on_delete: :restrict), null: false, default: 1
    end

    create index(:users, [:role_id])
    create unique_index(:users, [:email])
  end
end
