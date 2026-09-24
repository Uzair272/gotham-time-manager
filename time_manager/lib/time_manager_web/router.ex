defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TimeManagerWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]

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
