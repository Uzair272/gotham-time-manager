defmodule TimeManager.Role do
  use Ecto.Schema

  # Roles are fixed: they are created by the migration and can only be read.
  @employee_id 1

  schema "roles" do
    field :name, :string

    has_many :users, TimeManager.User

    timestamps(type: :utc_datetime)
  end

  @doc "Id of the default role given to every new user."
  def employee_id, do: @employee_id
end
