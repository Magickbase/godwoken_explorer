defmodule GodwokenIndexer.Worker.GenerateERC20SeriesContract do
  @moduledoc """
  Import godwoken bridge contract to `GodwokenExplorer.SmartContract`.
  """
  use Oban.Worker, queue: :default, unique: [period: 300, states: Oban.Job.states()]

  import Ecto.Query, only: [preload: 2]

  alias GodwokenExplorer.{Repo, Account, UDT, SmartContract}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    with account when account != nil <-
           Repo.get(Account, account_id),
         udt when is_nil(udt) <- Repo.get(UDT, account_id),
         smart_contract when is_nil(smart_contract) <- Repo.get(SmartContract, account_id) do
      erc20_account = Account |> preload(:smart_contract) |> Repo.get(Account.erc20_sample_id())

      Repo.insert(
        %SmartContract{
          name: "ERC20",
          account_id: account.id,
          abi: erc20_account.smart_contract.abi,
          contract_source_code: erc20_account.smart_contract.contract_source_code,
          compiler_version: erc20_account.smart_contract.compiler_version
        },
        on_conflict: {:replace, [:name, :abi, :contract_source_code, :compiler_version]},
        conflict_target: :account_id
      )
    end

    :ok
  end
end
