defmodule TimeManager.Accounts do
  @moduledoc """
  Everything about users, roles and teams: sign up, sign in, who can see whom.
  Controllers call these functions instead of talking to the Repo directly.
  """

  import Ecto.Query

  alias TimeManager.{Repo, Role, Team, User}

  # ---------- users ----------

  def get_user(id), do: Repo.get(User, id) |> Repo.preload(:role)

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> preload_role()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> preload_role()
  end

  @doc "Returns {:ok, user} when email and password match, :error otherwise."
  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    user =
      User
      |> where([u], fragment("lower(?)", u.email) == ^String.downcase(email))
      |> Repo.one()
      |> Repo.preload(:role)

    if User.valid_password?(user, password), do: {:ok, user}, else: :error
  end

  def authenticate(_email, _password), do: :error

  @doc """
  Users that `current` is allowed to list.
  Admins and managers see the whole directory (a manager needs it to add people
  to their teams); everyone else only sees themself.
  Seeing someone in the list does NOT give access to their clocks or working
  times: that is checked by can_access_user?/2.
  """
  def visible_users_query(%User{} = current) do
    if admin?(current) or manager?(current) do
      User
    else
      from(u in User, where: u.id == ^current.id)
    end
  end

  def to_map(%User{} = user) do
    user = Repo.preload(user, :role)

    %{
      id: user.id,
      username: user.username,
      email: user.email,
      role_id: user.role_id,
      role: user.role && user.role.name
    }
  end

  # ---------- roles ----------

  def list_roles, do: Repo.all(from r in Role, order_by: r.id)

  def change_role(%User{} = user, role_name) do
    case Repo.get_by(Role, name: role_name) do
      nil ->
        {:error, :unknown_role}

      role ->
        user
        |> User.role_changeset(role.id)
        |> Repo.update()
        |> preload_role(true)
    end
  end

  # ---------- permissions ----------

  def admin?(%User{} = user), do: role_name(user) == "admin"
  def manager?(%User{} = user), do: role_name(user) == "manager"

  @doc """
  Can `current` see and manage the data (clocks, working times) of user `target_id`?
  - yourself: yes
  - admin: everyone
  - manager: the members of the teams they manage
  """
  def can_access_user?(%User{} = current, target_id) do
    case to_int(target_id) do
      nil -> false
      id when id == current.id -> true
      id -> admin?(current) or (manager?(current) and manages_user?(current.id, id))
    end
  end

  def manages_user?(manager_id, user_id) do
    from(m in "team_members",
      join: t in Team,
      on: t.id == m.team_id,
      where: t.manager_id == ^manager_id and m.user_id == ^user_id
    )
    |> Repo.exists?()
  end

  # ---------- teams ----------

  def list_teams_for(%User{} = user) do
    base = from(t in Team, order_by: t.id)

    query =
      if admin?(user) do
        base
      else
        from(t in base,
          left_join: m in "team_members",
          on: m.team_id == t.id,
          where: t.manager_id == ^user.id or m.user_id == ^user.id,
          distinct: true
        )
      end

    query |> Repo.all() |> Repo.preload([:manager, :members])
  end

  def get_team(id), do: Repo.get(Team, id) |> Repo.preload([:manager, :members])

  def create_team(attrs), do: %Team{} |> Team.changeset(attrs) |> Repo.insert()

  def update_team(%Team{} = team, attrs), do: team |> Team.changeset(attrs) |> Repo.update()

  def delete_team(%Team{} = team), do: Repo.delete(team)

  def can_see_team?(%User{} = user, %Team{} = team) do
    admin?(user) or team.manager_id == user.id or Enum.any?(team.members, &(&1.id == user.id))
  end

  def can_manage_team?(%User{} = user, %Team{} = team) do
    admin?(user) or team.manager_id == user.id
  end

  def add_member(%Team{} = team, user_id) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      user ->
        Repo.insert_all("team_members", [%{team_id: team.id, user_id: user.id}],
          on_conflict: :nothing
        )

        {:ok, get_team(team.id)}
    end
  end

  def remove_member(%Team{} = team, user_id) do
    case to_int(user_id) do
      nil ->
        {:error, :user_not_found}

      id ->
        from(m in "team_members", where: m.team_id == ^team.id and m.user_id == ^id)
        |> Repo.delete_all()

        {:ok, get_team(team.id)}
    end
  end

  def team_to_map(%Team{} = team) do
    %{
      id: team.id,
      name: team.name,
      manager_id: team.manager_id,
      manager: team.manager && %{id: team.manager.id, username: team.manager.username},
      members:
        Enum.map(team.members, fn u -> %{id: u.id, username: u.username, email: u.email} end)
    }
  end

  # ---------- helpers ----------

  defp role_name(%User{role: %Role{name: name}}), do: name
  defp role_name(_), do: nil

  defp preload_role(result, force \\ false)
  defp preload_role({:ok, user}, force), do: {:ok, Repo.preload(user, :role, force: force)}
  defp preload_role(error, _force), do: error

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp to_int(_), do: nil
end
