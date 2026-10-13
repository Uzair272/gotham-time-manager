defmodule TimeManager.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string

    belongs_to :manager, TimeManager.User
    many_to_many :members, TimeManager.User, join_through: "team_members"

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :manager_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> assoc_constraint(:manager)
  end
end
