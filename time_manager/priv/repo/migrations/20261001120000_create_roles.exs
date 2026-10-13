defmodule TimeManager.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def up do
    create table(:roles) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])

    # Roles are fixed (no CRUD), so they are inserted every time the table is created.
    # The ids are fixed too: 1 = employee (default), 2 = manager, 3 = admin.
    execute """
    INSERT INTO roles (id, name, inserted_at, updated_at) VALUES
      (1, 'employee', NOW(), NOW()),
      (2, 'manager', NOW(), NOW()),
      (3, 'admin', NOW(), NOW())
    """

    execute "SELECT setval('roles_id_seq', 3)"
  end

  def down do
    drop table(:roles)
  end
end
