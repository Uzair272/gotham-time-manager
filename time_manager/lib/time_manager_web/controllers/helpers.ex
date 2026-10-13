defmodule TimeManagerWeb.Helpers do
  @moduledoc "Small response helpers shared by the controllers."

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def forbidden(conn) do
    conn |> put_status(:forbidden) |> json(%{error: "You are not allowed to do this"})
  end

  def not_found(conn, what) do
    conn |> put_status(:not_found) |> json(%{error: "#{what} not found"})
  end

  def bad_request(conn, message) do
    conn |> put_status(:bad_request) |> json(%{error: message})
  end

  def changeset_error(conn, changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end
end
