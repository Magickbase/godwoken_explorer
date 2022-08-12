defmodule GodwokenExplorerWeb.Router do
  use GodwokenExplorerWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:auth)
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

    if Application.get_env(:godwoken_explorer, :graphiql) do
      get("/", Absinthe.Plug.GraphiQL,
        schema: GodwokenExplorer.Graphql.Schemas.Graphql,
        interface: :playground,
        log_level: :info,
        adapter: Absinthe.Adapter.Underscore
      )
    end

    post("/", Absinthe.Plug,
      schema: GodwokenExplorer.Graphql.Schemas.Graphql,
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
    get("/daily_stats", DailyStatController, :index)
    get("/txs/:hash/logs", Transaction.LogController, :index)
    get("/accounts/:address/logs", Account.LogController, :index)
    get("/poly_versions", PolyVersionController, :index)
    get("/snapshots.csv", SnapshotController, :index)
  end

  scope "/api/v1", as: :api_v1 do
    pipe_through(:api)
    alias GodwokenExplorerWeb.API.RPC

    forward("/", RPC.RPCTranslator, %{
      "account" => {RPC.AccountController, []},
      "contract" => {RPC.ContractController, []},
      "block" => {RPC.BlockController, []},
      "logs" => {RPC.LogsController, []},
      "stats" => {RPC.StatsController, []}
    })
  end

  scope "/", GodwokenExplorerWeb do
    get("/", RootController, :index)
  end

  scope "/admin", GodwokenExplorerWeb.Admin, as: :admin do
    pipe_through(:browser)

    get("/", UDTController, :index)
    resources("/udts", UDTController, except: [:delete])
    resources("/smart_contracts", SmartContractController, except: [:delete])
    resources("/jobs", JobController, only: [:index, :show, :delete])
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

  defp auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(conn, Application.get_env(:godwoken_explorer, :basic_auth))
  end
end
