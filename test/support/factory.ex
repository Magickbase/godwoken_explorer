defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: GodwokenExplorer.Repo

  use GodwokenExplorer.UtilFactory
  use GodwokenExplorer.AccountFactory
  use GodwokenExplorer.BlockFactory
  use GodwokenExplorer.ContractMethodFactory
  use GodwokenExplorer.CurrentBridgedUDTBalanceFactory
  use GodwokenExplorer.CurrentUDTBalanceFactory
  use GodwokenExplorer.DepositHistoryFactory
  use GodwokenExplorer.LogFactory
  use GodwokenExplorer.PolyjuiceFactory
  use GodwokenExplorer.PolyjuiceCreatorFactory
  use GodwokenExplorer.SmartContractFactory
  use GodwokenExplorer.TokenTransferFactory
  use GodwokenExplorer.TransactionFactory
  use GodwokenExplorer.UDTFactory
  use GodwokenExplorer.WithdrawalHistoryFactory
  use GodwokenExplorer.WithdrawalRequestFactory

  alias GodwokenExplorer.Repo

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
