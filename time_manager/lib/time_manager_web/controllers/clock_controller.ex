defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.{Repo, User, Clock}

  # GET /api/clocks/:user_id -> all clocks of a user, newest first
  def index(conn, %{"user_id" => user_id}) do
    case Repo.get(User, user_id) do
      nil ->
        user_not_found(conn)

      user ->
        clocks =
          Clock
          |> where([c], c.user_id == ^user.id)
          |> order_by([c], desc: c.time, desc: c.id)
          |> Repo.all()

        json(conn, %{data: Enum.map(clocks, &to_map/1)})
    end
  end

  # POST /api/clocks/:user_id -> clock in OR clock out, decided by the last clock
  def create(conn, %{"user_id" => user_id} = params) do
    attrs = clock_params(params)

    with {:ok, user} <- find_user(user_id),
         {:ok, time} <- parse_time(attrs["time"]),
         {:ok, status} <- decide_status(user, attrs["status"]) do
      new_clock = %{"time" => time, "status" => status, "user_id" => user.id}

      case Repo.insert(Clock.changeset(%Clock{}, new_clock)) do
        {:ok, clock} ->
          conn |> put_status(:created) |> json(%{data: to_map(clock)})

        {:error, changeset} ->
          conn |> put_status(:bad_request) |> json(%{errors: errors_to_map(changeset)})
      end
    else
      {:error, :user_not_found} ->
        user_not_found(conn)

      {:error, :bad_date} ->
        bad_request(conn, "time must look like YYYY-MM-DD HH:mm:ss")

      {:error, :bad_status} ->
        bad_request(conn, "status must be true or false")

      {:error, {:wrong_status, expected}} ->
        bad_request(conn, "wrong status: the next clock for this user must be #{expected}")
    end
  end

  # ---- helpers ----

  defp find_user(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  # No last clock, or last clock was a departure -> next is an arrival (true).
  # Last clock was an arrival -> next is a departure (false).
  defp next_status(user) do
    last =
      Clock
      |> where([c], c.user_id == ^user.id)
      |> order_by([c], desc: c.id)
      |> limit(1)
      |> Repo.one()

    not (last != nil and last.status == true)
  end

  # No status sent: we decide. Status sent: it must match what we would decide.
  defp decide_status(user, given) do
    next = next_status(user)

    case given do
      nil ->
        {:ok, next}

      value ->
        case normalize_status(value) do
          ^next -> {:ok, next}
          :invalid -> {:error, :bad_status}
          _ -> {:error, {:wrong_status, next}}
        end
    end
  end

  defp normalize_status(true), do: true
  defp normalize_status("true"), do: true
  defp normalize_status(false), do: false
  defp normalize_status("false"), do: false
  defp normalize_status(_), do: :invalid

  # No time sent: use the server's current time.
  defp parse_time(nil), do: {:ok, DateTime.utc_now() |> DateTime.truncate(:second)}

  defp parse_time(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, DateTime.truncate(datetime, :second)}

      {:error, _} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} ->
            {:ok, naive |> DateTime.from_naive!("Etc/UTC") |> DateTime.truncate(:second)}

          {:error, _} ->
            {:error, :bad_date}
        end
    end
  end

  defp user_not_found(conn) do
    conn |> put_status(:not_found) |> json(%{error: "User not found"})
  end

  defp bad_request(conn, message) do
    conn |> put_status(:bad_request) |> json(%{error: message})
  end

  defp clock_params(params), do: Map.get(params, "clock", params)

  defp to_map(clock) do
    %{id: clock.id, time: clock.time, status: clock.status, user_id: clock.user_id}
  end

  defp errors_to_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
