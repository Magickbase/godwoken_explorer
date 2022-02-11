defmodule GodwokenExplorer.Repo do
  use Ecto.Repo,
    otp_app: :godwoken_explorer,
    adapter: Ecto.Adapters.Postgres

  use Scrivener
  use ExAudit.Repo
end
