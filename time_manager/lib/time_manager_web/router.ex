defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Signed-in users only: checks the JWT cookie + the x-xsrf-token header
  pipeline :auth do
    plug TimeManagerWeb.Plugs.Authenticate
  end

  pipeline :manager_or_admin do
    plug TimeManagerWeb.Plugs.RequireRole, ["manager", "admin"]
  end

  pipeline :admin_only do
    plug TimeManagerWeb.Plugs.RequireRole, ["admin"]
  end

  # ---------- public routes ----------
  scope "/api", TimeManagerWeb do
    pipe_through :api

    post "/users/sign_up", AuthController, :sign_up
    post "/users/sign_in", AuthController, :sign_in
  end

  # ---------- any signed-in user ----------
  # (controllers also check that you only touch data you are allowed to see)
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :auth]

    post "/users/sign_out", AuthController, :sign_out
    get "/users/me", AuthController, :me
    get "/users/:id", UserController, :show
    put "/users/:id", UserController, :update

    get "/roles", RoleController, :index

    get "/teams", TeamController, :index
    get "/teams/:id", TeamController, :show
    # admin, or the manager of that team
    post "/teams/:id/users/:user_id", TeamController, :add_member
    delete "/teams/:id/users/:user_id", TeamController, :remove_member

    scope "/workingtime" do
      get "/:user_id", WorkingTimeController, :index
      get "/:user_id/:id", WorkingTimeController, :show
      post "/:user_id", WorkingTimeController, :create
      put "/:id", WorkingTimeController, :update
      delete "/:id", WorkingTimeController, :delete
    end

    scope "/clocks" do
      get "/:user_id", ClockController, :index
      post "/:user_id", ClockController, :create
    end
  end

  # ---------- managers and admins ----------
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :auth, :manager_or_admin]

    get "/users", UserController, :index
  end

  # ---------- admins only ----------
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :auth, :admin_only]

    post "/users", UserController, :create
    delete "/users/:id", UserController, :delete
    put "/users/:id/role", UserController, :update_role

    post "/teams", TeamController, :create
    put "/teams/:id", TeamController, :update
    delete "/teams/:id", TeamController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:time_manager, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TimeManagerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
