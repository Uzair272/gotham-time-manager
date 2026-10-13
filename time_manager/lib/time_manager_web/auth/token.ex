defmodule TimeManagerWeb.Auth.Token do
  @moduledoc """
  JSON Web Token handling (Joken library).

  The JWT contains: the xsrf token, the user id, the role, and expires after 30 days.
  It is signed with the secret configured in config/runtime.exs (HS256).
  """

  use Joken.Config

  @max_age 30 * 24 * 60 * 60
  @cookie "time_manager_jwt"

  def max_age, do: @max_age
  def cookie_name, do: @cookie

  @impl true
  def token_config do
    default_claims(default_exp: @max_age, iss: "time_manager", aud: "time_manager")
  end

  @doc "Random 50-character token, returned to the front-end at sign in."
  def new_xsrf_token do
    :crypto.strong_rand_bytes(48)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 50)
  end

  @doc "Builds and signs the JWT for a user. Returns {:ok, jwt, claims}."
  def create(user, xsrf_token) do
    generate_and_sign(%{
      "user_id" => user.id,
      "role" => user.role.name,
      "xsrf" => xsrf_token
    })
  end
end
