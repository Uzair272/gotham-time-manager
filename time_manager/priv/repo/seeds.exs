# Creates the first accounts. Safe to run several times (it skips what already exists).
#
#     mix run priv/repo/seeds.exs
#
# Roles (employee, manager, admin) are not created here: the migration inserts them.

alias TimeManager.{Accounts, Repo, Team, User}

admin_password = System.get_env("ADMIN_PASSWORD", "Admin1234!")

accounts = [
  # {username, email, password, role id}  -> 1 employee, 2 manager, 3 admin
  {"admin", "admin@gotham.city", admin_password, 3},
  {"gordon", "manager@gotham.city", "Manager1234!", 2},
  {"bruce", "employee@gotham.city", "Employee1234!", 1}
]

users =
  for {username, email, password, role_id} <- accounts do
    case Repo.get_by(User, email: email) do
      nil ->
        %User{}
        |> User.registration_changeset(%{username: username, email: email, password: password})
        |> Ecto.Changeset.put_change(:role_id, role_id)
        |> Repo.insert!()

      existing ->
        existing
    end
  end

[_admin, manager, employee] = users

# A demo team: the manager manages it, the employee is a member
team =
  Repo.get_by(Team, name: "City Hall") ||
    Repo.insert!(%Team{name: "City Hall", manager_id: manager.id})

{:ok, _} = Accounts.add_member(team, employee.id)

IO.puts("""
Seeds done. You can sign in with:
  admin@gotham.city    / #{admin_password}   (admin)
  manager@gotham.city  / Manager1234!        (manager)
  employee@gotham.city / Employee1234!       (employee)
""")
