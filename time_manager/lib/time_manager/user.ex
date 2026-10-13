defmodule TimeManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias TimeManager.Role

  schema "users" do
    field :username, :string
    field :email, :string
    # "password" is only kept in memory (virtual); the database stores the hash
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    belongs_to :role, TimeManager.Role
    has_many :clocks, TimeManager.Clock
    has_many :working_times, TimeManager.WorkingTime
    many_to_many :teams, TimeManager.Team, join_through: "team_members"
    has_many :managed_teams, TimeManager.Team, foreign_key: :manager_id

    timestamps(type: :utc_datetime)
  end

  @doc "Sign up / creation: the password is required. Role is always employee."
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_email()
    |> hash_password()
    |> put_default_role()
  end

  @doc "Profile update: the password is optional (only changed if sent)."
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email])
    |> validate_email()
    |> hash_password()
  end

  @doc "Promotion / demotion: only an admin route uses this."
  def role_changeset(user, role_id) do
    user
    |> change(role_id: role_id)
    |> assoc_constraint(:role)
  end

  @doc "Checks a plain password against the stored hash."
  def valid_password?(%__MODULE__{password_hash: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def valid_password?(_user, _password) do
    # Takes the same time as a real check, so attackers can't guess which emails exist
    Bcrypt.no_user_verify()
    false
  end

  defp validate_email(changeset) do
    changeset
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: "must be a valid email like X@X.X"
    )
    |> unique_constraint(:email, message: "is already used")
  end

  defp hash_password(changeset) do
    changeset = validate_length(changeset, :password, min: 8, max: 72)

    case {changeset.valid?, get_change(changeset, :password)} do
      {true, password} when is_binary(password) ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)

      _ ->
        changeset
    end
  end

  defp put_default_role(changeset) do
    if get_field(changeset, :role_id) do
      changeset
    else
      put_change(changeset, :role_id, Role.employee_id())
    end
  end
end
