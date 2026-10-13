defmodule TimeManager.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      # The manager in charge of the team (optional)
      add :manager_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:name])
    create index(:teams, [:manager_id])

    # Join table: an employee can be in several teams, a team has several employees
    create table(:team_members, primary_key: false) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create unique_index(:team_members, [:team_id, :user_id])
    create index(:team_members, [:user_id])
  end
end
