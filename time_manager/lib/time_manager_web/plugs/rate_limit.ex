defmodule TimeManagerWeb.Plugs.RateLimit do
  @moduledoc """
  Blocks a client that makes too many requests to a sensitive route.
  Keyed on the client's IP + the route name. Over the limit -> 429.
  Usage in a controller: plug TimeManagerWeb.Plugs.RateLimit, [name: "sign_in", limit: 5, window_ms: 60_000]
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias TimeManager.RateLimiter

  def init(opts), do: opts

  def call(conn, opts) do
    name = Keyword.fetch!(opts, :name)
    limit = Keyword.get(opts, :limit, 10)
    window = Keyword.get(opts, :window_ms, 60_000)

    key = "#{name}:#{client_ip(conn)}"

    case RateLimiter.hit(key, limit, window) do
      :ok ->
        conn

      :blocked ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Too many attempts. Please wait a minute and try again."})
        |> halt()
    end
  end

  # Use the real client IP if a proxy set X-Forwarded-For, else the socket IP
  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [value | _] -> value |> String.split(",") |> List.first() |> String.trim()
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end