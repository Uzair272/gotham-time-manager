defmodule TimeManagerWeb.Plugs.Authenticate do
  @moduledoc """
  Runs before every protected route:
  1. reads the JWT from the HttpOnly cookie,
  2. checks its signature and expiry,
  3. checks that the x-xsrf-token header matches the xsrf token inside the JWT,
  4. loads the user (with its role) into conn.assigns.current_user.
  Anything wrong -> 401 Unauthorized.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias TimeManager.Accounts
  alias TimeManagerWeb.Auth.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    with jwt when is_binary(jwt) <- conn.cookies[Token.cookie_name()],
         {:ok, claims} <- Token.verify_and_validate(jwt),
         [xsrf_header | _] <- get_req_header(conn, "x-xsrf-token"),
         xsrf_in_jwt when is_binary(xsrf_in_jwt) <- claims["xsrf"],
         true <- Plug.Crypto.secure_compare(xsrf_header, xsrf_in_jwt),
         user_id when is_integer(user_id) <- claims["user_id"],
         %TimeManager.User{} = user <- Accounts.get_user(user_id) do
      # The role is re-read from the database, so a promotion/demotion applies immediately
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "You must be signed in"})
        |> halt()
    end
  end
end
