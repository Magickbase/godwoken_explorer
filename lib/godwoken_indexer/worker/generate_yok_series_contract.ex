defmodule GodwokenIndexer.Worker.GenerateYokSeriesContract do
  use Oban.Worker, queue: :default, unique: [period: 300, states: Oban.Job.states()]

  import Ecto.Query, only: [preload: 2]

  alias GodwokenExplorer.{Repo, Account, UDT, SmartContract}

  @yok_mainnet_account_id 12119

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    with account when account != nil <-
           Repo.get(Account, account_id),
         udt when is_nil(udt) <- Repo.get(UDT, account_id),
         smart_contract when is_nil(smart_contract) <- Repo.get(SmartContract, account_id) do
      Repo.transaction(fn ->
        decimal = UDT.eth_call_decimal(account.eth_address)
        supply = UDT.eth_call_total_supply(account.eth_address)
        name = UDT.eth_call_name(account.eth_address)
        symbol = UDT.eth_call_symbol(account.eth_address)

        Repo.insert!(%UDT{
          name: name,
          symbol: symbol,
          supply: supply,
          decimal: decimal,
          id: account.id,
          bridge_account_id: account.id,
          type: :native
        })

        yok_account = Account |> preload(:smart_contract) |> Repo.get(@yok_mainnet_account_id)

        Repo.insert!(%SmartContract{
          name: name,
          account_id: account.id,
          abi: yok_account.smart_contract.abi,
          contract_source_code: yok_account.smart_contract.contract_source_code
        })
      end)
    end

    :ok
  end
end
