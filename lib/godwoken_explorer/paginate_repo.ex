defmodule GodwokenExplorer.PaginateRepo do
  use Ecto.Repo,
    otp_app: :godwoken_explorer,
    adapter: Ecto.Adapters.Postgres

  use Paginator,
    # sets the default limit to 10
    limit: 20,
    # sets the maximum limit to 100
    maximum_limit: 100,
    # include total count by default
    include_total_count: true
end
