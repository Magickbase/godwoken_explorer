defmodule GodwokenExplorer.Repo do
  use Ecto.Repo,
    otp_app: :godwoken_explorer,
    adapter: Ecto.Adapters.Postgres
end
