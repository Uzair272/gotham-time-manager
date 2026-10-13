defmodule TimeManagerWeb.Plugs.RequireRole do
  @moduledoc """
  Only lets the request through if the signed-in user has one of the given roles.
  Use it after Authenticate, e.g. `plug RequireRole, ["admin"]`. Otherwise -> 403 Forbidden.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(roles), do: Enum.map(List.wrap(roles), &to_string/1)

  def call(conn, roles) do
    user = conn.assigns[:current_user]

    if user && user.role && user.role.name in roles do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You are not allowed to do this"})
      |> halt()
    end
  end
end
