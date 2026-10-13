defmodule TimeManagerWeb.TeamController do
  use TimeManagerWeb, :controller

  import TimeManagerWeb.Helpers

  alias TimeManager.Accounts

  # GET /api/teams -> admin: all teams, others: teams they manage or belong to
  def index(conn, _params) do
    teams = Accounts.list_teams_for(conn.assigns.current_user)
    json(conn, %{data: Enum.map(teams, &Accounts.team_to_map/1)})
  end

  # GET /api/teams/:id
  def show(conn, %{"id" => id}) do
    with %{} = team <- Accounts.get_team(id),
         true <- Accounts.can_see_team?(conn.assigns.current_user, team) || :forbidden do
      json(conn, %{data: Accounts.team_to_map(team)})
    else
      nil -> not_found(conn, "Team")
      :forbidden -> forbidden(conn)
    end
  end

  # POST /api/teams  (admin)  Body: {"name": "...", "manager_id": 2}
  def create(conn, params) do
    case Accounts.create_team(team_params(params)) do
      {:ok, team} ->
        conn
        |> put_status(:created)
        |> json(%{data: Accounts.team_to_map(Accounts.get_team(team.id))})

      {:error, changeset} ->
        changeset_error(conn, changeset)
    end
  end

  # PUT /api/teams/:id  (admin)
  def update(conn, %{"id" => id} = params) do
    with %{} = team <- Accounts.get_team(id),
         {:ok, team} <- Accounts.update_team(team, team_params(params)) do
      json(conn, %{data: Accounts.team_to_map(Accounts.get_team(team.id))})
    else
      nil -> not_found(conn, "Team")
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  # DELETE /api/teams/:id  (admin)
  def delete(conn, %{"id" => id}) do
    case Accounts.get_team(id) do
      nil ->
        not_found(conn, "Team")

      team ->
        {:ok, _} = Accounts.delete_team(team)
        send_resp(conn, :no_content, "")
    end
  end

  # POST /api/teams/:id/users/:user_id  (admin, or the manager of this team)
  def add_member(conn, %{"id" => id, "user_id" => user_id}) do
    with %{} = team <- Accounts.get_team(id),
         true <- Accounts.can_manage_team?(conn.assigns.current_user, team) || :forbidden,
         {:ok, team} <- Accounts.add_member(team, user_id) do
      json(conn, %{data: Accounts.team_to_map(team)})
    else
      nil -> not_found(conn, "Team")
      :forbidden -> forbidden(conn)
      {:error, :user_not_found} -> not_found(conn, "User")
    end
  end

  # DELETE /api/teams/:id/users/:user_id  (admin, or the manager of this team)
  def remove_member(conn, %{"id" => id, "user_id" => user_id}) do
    with %{} = team <- Accounts.get_team(id),
         true <- Accounts.can_manage_team?(conn.assigns.current_user, team) || :forbidden,
         {:ok, team} <- Accounts.remove_member(team, user_id) do
      json(conn, %{data: Accounts.team_to_map(team)})
    else
      nil -> not_found(conn, "Team")
      :forbidden -> forbidden(conn)
      {:error, :user_not_found} -> not_found(conn, "User")
    end
  end

  defp team_params(params), do: Map.get(params, "team", params)
end
