defmodule GodwokenIndexer.Worker.ImportContractCode do
  use Oban.Worker, queue: :default, unique: [period: 300, states: Oban.Job.states()]

  alias GodwokenExplorer.{Repo, Account, Chain.Hash}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"block_number" => block_number, "address" => address}}) do
    {:ok,
     %{
       errors: [],
       params_list: [
         %{address: address, code: contract_code}
       ]
     }} = GodwokenRPC.fetch_codes([%{block_quantity: block_number, address: address}])

    {:ok, address_hash} = Hash.Address.cast(address)

    {:ok, %Account{id: id}} =
      case Account.search(address_hash) do
        %Account{} = account ->
          account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()

        nil ->
          {:ok, account} = Account.find_or_create_contract_by_eth_address(address)
          account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()
      end

    compare_with_yok_contract(contract_code, id)
    :ok
  end

  defp compare_with_yok_contract(contract_code, account_id) do
    if System.get_env("GODWOKEN_CHAIN") == "mainnet" &&
         Account.yok_contract_code() == contract_code do
      %{account_id: account_id}
      |> GodwokenIndexer.Worker.GenerateYokSeriesContract.new()
      |> Oban.insert()
    end
  end
end
