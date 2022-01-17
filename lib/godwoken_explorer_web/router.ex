defmodule GodwokenExplorerWeb.Router do
  use GodwokenExplorerWeb, :router

  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :basic_auth, Application.compile_env(:godwoken_explorer, :basic_auth)
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", GodwokenExplorerWeb.API do
    get("/home", HomeController, :index)
    get("/blocks/:id", BlockController, :show)
    get("/txs/:hash", TransactionController, :show)
    get("/txs", TransactionController, :index)
    get("/transfers", TransferController, :index)
    get("/accounts/:id", AccountController, :show)
    get("/search", SearchController, :index)
    get("/withdrawal_histories", WithdrawalHistoryController, :index)
    get("/udts", UDTController, :index)
    get("/udts/:id", UDTController, :show)
  end

  scope "/", GodwokenExplorerWeb do
    get "/", RootController, :index
  end

  scope "/admin", GodwokenExplorerWeb.Admin, as: :admin do
    pipe_through :browser

    get "/", UDTController, :index
    resources "/udts", UDTController
    resources "/smart_contracts", SmartContractController

  end

  # Other scopes may use custom stacks.
  # scope "/api", GodwokenExplorerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  scope "/" do
    pipe_through :browser

    live_dashboard "/dashboard",
      metrics: GodwokenExplorerWeb.Telemetry,
      ecto_repos: [GodwokenExplorer.Repo]
  end
end
