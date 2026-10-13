defmodule TimeManagerWeb.AuthController do
  use TimeManagerWeb, :controller

  import TimeManagerWeb.Helpers

  alias TimeManager.Accounts
  alias TimeManagerWeb.Auth.Token

  # POST /api/users/sign_up  (public)
  # Body: {"username": "...", "email": "...", "password": "..."}
  def sign_up(conn, params) do
    case Accounts.register_user(Map.get(params, "user", params)) do
      {:ok, user} -> conn |> put_status(:created) |> json(%{data: Accounts.to_map(user)})
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  # POST /api/users/sign_in  (public)
  # Body: {"email": "...", "password": "..."}
  # Sets the JWT in an HttpOnly cookie and returns the xsrf token, the user id and the role.
  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        xsrf_token = Token.new_xsrf_token()
        {:ok, jwt, _claims} = Token.create(user, xsrf_token)

        conn
        |> put_resp_cookie(Token.cookie_name(), jwt,
          http_only: true,
          same_site: "Lax",
          max_age: Token.max_age()
        )
        |> json(%{
          xsrf_token: xsrf_token,
          user_id: user.id,
          role: user.role.name,
          user: Accounts.to_map(user)
        })

      :error ->
        conn |> put_status(:unauthorized) |> json(%{error: "Invalid email or password"})
    end
  end

  def sign_in(conn, _params), do: bad_request(conn, "email and password are required")

  # POST /api/users/sign_out  (signed in)
  # Deletes the JWT cookie.
  def sign_out(conn, _params) do
    conn
    |> delete_resp_cookie(Token.cookie_name(), http_only: true, same_site: "Lax")
    |> send_resp(:no_content, "")
  end

  # GET /api/users/me  (signed in) -> the current user
  def me(conn, _params) do
    json(conn, %{data: Accounts.to_map(conn.assigns.current_user)})
  end
end
