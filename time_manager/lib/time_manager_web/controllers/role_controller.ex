defmodule TimeManagerWeb.RoleController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts

  # GET /api/roles -> roles are read-only (no create/update/delete)
  def index(conn, _params) do
    roles = Enum.map(Accounts.list_roles(), fn r -> %{id: r.id, name: r.name} end)
    json(conn, %{data: roles})
  end
end
