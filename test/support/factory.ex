defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: GodwokenExplorer.Repo

  use GodwokenExplorer.UtilFactory
  use GodwokenExplorer.AccountFactory
  use GodwokenExplorer.CurrentBridgedUDTBalanceFactory
  use GodwokenExplorer.CurrentUDTBalanceFactory
  use GodwokenExplorer.BlockFactory
  use GodwokenExplorer.LogFactory
  use GodwokenExplorer.PolyjuiceFactory
  use GodwokenExplorer.TokenTransferFactory
  use GodwokenExplorer.TransactionFactory
  use GodwokenExplorer.UDTFactory

  alias GodwokenExplorer.Repo

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
