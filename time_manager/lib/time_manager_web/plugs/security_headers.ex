defmodule TimeManagerWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Adds standard security headers to every response.
  - X-Content-Type-Options: stops the browser from MIME-sniffing
  - X-Frame-Options: stops the site being embedded in an <iframe> (clickjacking)
  - Referrer-Policy: don't leak the full URL to other sites
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("referrer-policy", "no-referrer")
  end
end