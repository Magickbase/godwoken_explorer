{:ok, _} = Application.ensure_all_started(:ex_machina)

Mox.defmock(MockGodwokenRPC, for: GodwokenRPC)
Application.put_env(:godwoken_explorer, :rpc_module, MockGodwokenRPC)

Mox.defmock(GodwokenExplorer.ExchangeRates.Source.TestSource,
  for: GodwokenExplorer.ExchangeRates.Source
)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(GodwokenExplorer.Repo, :manual)
