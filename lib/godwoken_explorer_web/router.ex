defmodule GodwokenExplorerWeb.Router do
  use GodwokenExplorerWeb, :router

  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:basic_auth, Application.compile_env(:godwoken_explorer, :basic_auth))
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(GodwokenExplorerWeb.Plugs.PageSize)
  end

  pipeline :graphql_api do
    plug(:accepts, ["json"])
  end

  scope "/graphql" do
    pipe_through([:graphql_api])

    if Mix.env() in [:dev, :stg] do
      get("/frontend", Absinthe.Plug.GraphiQL,
        schema: GodwokenExplorer.Graphql.Schemas.Frontend,
        interface: :playground,
        log_level: :info,
        adapter: Absinthe.Adapter.Underscore
      )

      get("/dashboard", Absinthe.Plug.GraphiQL,
        schema: GodwokenExplorer.Graphql.Schemas.Dashboard,
        interface: :playground,
        log_level: :info,
        adapter: Absinthe.Adapter.Underscore
      )

      get("/web3api", Absinthe.Plug.GraphiQL,
        schema: GodwokenExplorer.Graphql.Schemas.Web3API,
        interface: :playground,
        log_level: :info,
        adapter: Absinthe.Adapter.Underscore
      )
    end

    post("/frontend", Absinthe.Plug,
      schema: GodwokenExplorer.Graphql.Schemas.Frontend,
      log_level: :info,
      adapter: Absinthe.Adapter.Underscore
    )

    post("/dashboard", Absinthe.Plug,
      schema: GodwokenExplorer.Graphql.Schemas.Dashboard,
      log_level: :info,
      adapter: Absinthe.Adapter.Underscore
    )

    post("/web3api", Absinthe.Plug,
      schema: GodwokenExplorer.Graphql.Schemas.Web3API,
      log_level: :info,
      adapter: Absinthe.Adapter.Underscore
    )
  end

  scope "/api", GodwokenExplorerWeb.API do
    pipe_through(:api)

    get("/home", HomeController, :index)
    get("/blocks", BlockController, :index)
    get("/blocks/:id", BlockController, :show)
    get("/txs/:hash", TransactionController, :show)
    get("/txs", TransactionController, :index)
    get("/transfers", TransferController, :index)
    get("/accounts/:id", AccountController, :show)
    get("/search", SearchController, :index)
    get("/withdrawal_histories", WithdrawalHistoryController, :index)
    get("/deposit_histories", DepositHistoryController, :index)
    get("/withdrawal_requests", WithdrawalRequestController, :index)
    get("/deposit_withdrawals", DepositWithdrawalController, :index)
    get("/udts", UDTController, :index)
    get("/udts/:id", UDTController, :show)
    get("/smart_contracts", SmartContractController, :index)
    get("/account_udts", AccountUDTController, :index)
  end

  scope "/", GodwokenExplorerWeb do
    get("/", RootController, :index)
  end

  scope "/admin", GodwokenExplorerWeb.Admin, as: :admin do
    pipe_through(:browser)

    get("/", UDTController, :index)
    resources("/udts", UDTController)
    resources("/smart_contracts", SmartContractController)
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
    pipe_through(:browser)

    live_dashboard("/dashboard",
      metrics: GodwokenExplorerWeb.Telemetry,
      ecto_repos: [GodwokenExplorer.Repo]
    )
  end
end
