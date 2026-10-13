defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller

  import Ecto.Query
  import TimeManagerWeb.Helpers

  alias TimeManager.{Accounts, Repo}

  # GET /api/users?email=XXX&username=YYY  (manager or admin)
  # Directory of users (only names/emails/roles, no clocks or working times).
  def index(conn, params) do
    users =
      conn.assigns.current_user
      |> Accounts.visible_users_query()
      |> filter_by(:email, params["email"])
      |> filter_by(:username, params["username"])
      |> order_by([u], u.id)
      |> Repo.all()
      |> Repo.preload(:role)

    json(conn, %{data: Enum.map(users, &Accounts.to_map/1)})
  end

  # GET /api/users/:id  (yourself, your team members if manager, anyone if admin)
  def show(conn, %{"id" => id}) do
    with true <- Accounts.can_access_user?(conn.assigns.current_user, id) || :forbidden,
         %{} = user <- Accounts.get_user(id) do
      json(conn, %{data: Accounts.to_map(user)})
    else
      :forbidden -> forbidden(conn)
      nil -> not_found(conn, "User")
    end
  end

  # POST /api/users  (admin) -> create a user with a password
  def create(conn, params) do
    case Accounts.register_user(user_params(params)) do
      {:ok, user} -> conn |> put_status(:created) |> json(%{data: Accounts.to_map(user)})
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  # PUT /api/users/:id  (yourself or admin) -> username, email, password (optional)
  def update(conn, %{"id" => id} = params) do
    current = conn.assigns.current_user

    with true <- self_or_admin?(current, id) || :forbidden,
         %{} = user <- Accounts.get_user(id),
         {:ok, user} <- Accounts.update_user(user, user_params(params)) do
      json(conn, %{data: Accounts.to_map(user)})
    else
      :forbidden -> forbidden(conn)
      nil -> not_found(conn, "User")
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  # PUT /api/users/:id/role  (admin) -> promote / demote. Body: {"role": "manager"}
  def update_role(conn, %{"id" => id, "role" => role}) do
    current = conn.assigns.current_user

    with false <- to_string(current.id) == to_string(id),
         %{} = user <- Accounts.get_user(id),
         {:ok, user} <- Accounts.change_role(user, role) do
      json(conn, %{data: Accounts.to_map(user)})
    else
      true -> bad_request(conn, "You cannot change your own role")
      nil -> not_found(conn, "User")
      {:error, :unknown_role} -> bad_request(conn, "role must be employee, manager or admin")
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  def update_role(conn, _params), do: bad_request(conn, "role is required")

  # DELETE /api/users/:id  (admin)
  def delete(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        not_found(conn, "User")

      user ->
        {:ok, _} = Repo.delete(user)
        send_resp(conn, :no_content, "")
    end
  end

  # ---- helpers ----

  defp self_or_admin?(current, id) do
    to_string(current.id) == to_string(id) or Accounts.admin?(current)
  end

  # No value given: keep the query as it is. Value given: keep only matching rows.
  defp filter_by(query, _field, nil), do: query
  defp filter_by(query, field, value), do: where(query, [u], field(u, ^field) == ^value)

  defp user_params(params), do: Map.get(params, "user", params)
end
