defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.{Repo, User}

  # GET /api/users?email=XXX&username=YYY
  # Without parameters: all users. With email and/or username: only the matching users.
  def index(conn, params) do
    users =
      User
      |> filter_by(:email, params["email"])
      |> filter_by(:username, params["username"])
      |> order_by([u], u.id)
      |> Repo.all()

    json(conn, %{data: Enum.map(users, &user_to_map/1)})
  end

  # GET /api/users/:id
  def show(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil -> not_found(conn)
      user -> json(conn, %{data: user_to_map(user)})
    end
  end

  # POST /api/users
  def create(conn, params) do
    changeset = User.changeset(%User{}, user_params(params))

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn |> put_status(:created) |> json(%{data: user_to_map(user)})

      {:error, changeset} ->
        conn |> put_status(:bad_request) |> json(%{errors: errors_to_map(changeset)})
    end
  end

  # PUT /api/users/:id
  def update(conn, %{"id" => id} = params) do
    case Repo.get(User, id) do
      nil ->
        not_found(conn)

      user ->
        case user |> User.changeset(user_params(params)) |> Repo.update() do
          {:ok, user} ->
            json(conn, %{data: user_to_map(user)})

          {:error, changeset} ->
            conn |> put_status(:bad_request) |> json(%{errors: errors_to_map(changeset)})
        end
    end
  end

  # DELETE /api/users/:id
  def delete(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil ->
        not_found(conn)

      user ->
        {:ok, _} = Repo.delete(user)
        send_resp(conn, :no_content, "")
    end
  end

  # ---- helpers ----

  # No value given: keep the query as it is. Value given: keep only matching rows.
  defp filter_by(query, _field, nil), do: query
  defp filter_by(query, field, value), do: where(query, [u], field(u, ^field) == ^value)

  defp not_found(conn) do
    conn |> put_status(:not_found) |> json(%{error: "User not found"})
  end

  defp user_params(params), do: Map.get(params, "user", params)

  defp user_to_map(user) do
    %{id: user.id, username: user.username, email: user.email}
  end

  defp errors_to_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
