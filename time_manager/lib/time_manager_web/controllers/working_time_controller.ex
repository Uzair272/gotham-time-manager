defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.{Accounts, Repo, User, WorkingTime}

  # Every action checks that the signed-in user may access this user's data
  # (yourself, your team members if you are a manager, anyone if you are an admin).

  # GET /api/workingtime/:user_id?start=XXX&end=YYY
  # All working times of a user; optionally only those inside the given period.
  def index(conn, %{"user_id" => user_id} = params) do
    with :ok <- check_access(conn, user_id),
         {:ok, user} <- find_user(user_id),
         {:ok, from_time} <- parse_optional(params["start"]),
         {:ok, to_time} <- parse_optional(params["end"]) do
      working_times =
        WorkingTime
        |> where([w], w.user_id == ^user.id)
        |> starting_after(from_time)
        |> ending_before(to_time)
        |> order_by([w], w.start)
        |> Repo.all()

      json(conn, %{data: Enum.map(working_times, &to_map/1)})
    else
      {:error, :forbidden} ->
        forbidden(conn)

      {:error, :user_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      {:error, :bad_date} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "start and end must look like YYYY-MM-DD HH:mm:ss"})
    end
  end

  # GET /api/workingtime/:user_id/:id
  def show(conn, %{"user_id" => user_id, "id" => id}) do
    with :ok <- check_access(conn, user_id),
         %WorkingTime{} = working_time <- Repo.get_by(WorkingTime, id: id, user_id: user_id) do
      json(conn, %{data: to_map(working_time)})
    else
      {:error, :forbidden} -> forbidden(conn)
      nil -> not_found(conn)
    end
  end

  # POST /api/workingtime/:user_id
  def create(conn, %{"user_id" => user_id} = params) do
    case check_access(conn, user_id) == :ok && Repo.get(User, user_id) do
      false ->
        forbidden(conn)

      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        attrs = params |> working_time_params() |> Map.put("user_id", user.id)

        case Repo.insert(WorkingTime.changeset(%WorkingTime{}, attrs)) do
          {:ok, working_time} ->
            conn |> put_status(:created) |> json(%{data: to_map(working_time)})

          {:error, changeset} ->
            conn |> put_status(:bad_request) |> json(%{errors: errors_to_map(changeset)})
        end
    end
  end

  # PUT /api/workingtime/:id  (only start and end can be changed)
  def update(conn, %{"id" => id} = params) do
    working_time = Repo.get(WorkingTime, id)

    cond do
      working_time == nil ->
        not_found(conn)

      check_access(conn, working_time.user_id) != :ok ->
        forbidden(conn)

      true ->
        attrs = params |> working_time_params() |> Map.take(["start", "end"])

        case working_time |> WorkingTime.changeset(attrs) |> Repo.update() do
          {:ok, working_time} ->
            json(conn, %{data: to_map(working_time)})

          {:error, changeset} ->
            conn |> put_status(:bad_request) |> json(%{errors: errors_to_map(changeset)})
        end
    end
  end

  # DELETE /api/workingtime/:id
  def delete(conn, %{"id" => id}) do
    working_time = Repo.get(WorkingTime, id)

    cond do
      working_time == nil ->
        not_found(conn)

      check_access(conn, working_time.user_id) != :ok ->
        forbidden(conn)

      true ->
        {:ok, _} = Repo.delete(working_time)
        send_resp(conn, :no_content, "")
    end
  end

  # ---- helpers ----

  defp check_access(conn, user_id) do
    if Accounts.can_access_user?(conn.assigns.current_user, user_id),
      do: :ok,
      else: {:error, :forbidden}
  end

  defp forbidden(conn) do
    conn |> put_status(:forbidden) |> json(%{error: "You are not allowed to do this"})
  end

  defp find_user(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  # No date given -> keep the query as it is
  defp starting_after(query, nil), do: query
  defp starting_after(query, from_time), do: where(query, [w], w.start >= ^from_time)

  defp ending_before(query, nil), do: query
  defp ending_before(query, to_time), do: where(query, [w], field(w, :end) <= ^to_time)

  # Accepts "2026-09-24 08:00:00" and also "2026-09-24T08:00:00Z"
  defp parse_optional(nil), do: {:ok, nil}

  defp parse_optional(value) do
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

  defp not_found(conn) do
    conn |> put_status(:not_found) |> json(%{error: "Working time not found"})
  end

  defp working_time_params(params), do: Map.get(params, "working_time", params)

  defp to_map(working_time) do
    %{
      id: working_time.id,
      start: working_time.start,
      end: Map.get(working_time, :end),
      user_id: working_time.user_id
    }
  end

  defp errors_to_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
