defmodule GodwokenExplorer.Repo do
  use Ecto.Repo,
    otp_app: :godwoken_explorer,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 20
  use ExAudit.Repo
end
