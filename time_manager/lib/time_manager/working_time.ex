defmodule TimeManager.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workingtime" do
    field :start, :utc_datetime
    field :end, :utc_datetime

    belongs_to :user, TimeManager.User

    timestamps(type: :utc_datetime)
  end

  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start, :end, :user_id])
    |> validate_required([:start, :end, :user_id])
    |> validate_end_after_start()
    |> assoc_constraint(:user)
  end

  defp validate_end_after_start(changeset) do
    start_time = get_field(changeset, :start)
    end_time = get_field(changeset, :end)

    if start_time && end_time && DateTime.compare(end_time, start_time) != :gt do
      add_error(changeset, :end, "must be after start")
    else
      changeset
    end
  end
end
