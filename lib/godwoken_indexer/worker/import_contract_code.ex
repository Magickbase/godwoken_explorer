defmodule GodwokenIndexer.Worker.ImportContractCode do
  @moduledoc """
  Fetch contract's contract_code and update.

  For Yokai series contract and godwoken bridge token contract, these contract code were same.
  So auto import contract to `GodwokenExplorer.SmartContract`
  """
  use Oban.Worker, queue: :default, unique: [period: 300, states: Oban.Job.states()]

  alias GodwokenExplorer.{Account, Chain, Repo}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"block_number" => block_number, "address" => address}}) do
    Account.handle_eoa_to_contract(address)

    {:ok,
     %{
       errors: [],
       params_list: [
         %{address: address, code: contract_code}
       ]
     }} = GodwokenRPC.fetch_codes([%{block_quantity: block_number, address: address}])

    {:ok, %Account{id: id}} =
      with {:ok, address_hash} <-
             Chain.string_to_address_hash(address),
           %Account{} = account <-
             Repo.get_by(Account, eth_address: address_hash) do
        account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()
      else
        nil ->
          {:ok, account} = Account.find_or_create_contract_by_eth_address(address)
          account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()
      end

    compare_with_yok_contract(contract_code, id)
    compare_with_erc20_contract(contract_code, id)
    :ok
  end

  defp compare_with_yok_contract(contract_code, account_id) do
    if Account.yok_contract_code() == contract_code do
      %{account_id: account_id}
      |> GodwokenIndexer.Worker.GenerateYokSeriesContract.new()
      |> Oban.insert()
    end
  end

  defp compare_with_erc20_contract(contract_code, account_id) do
    if Account.erc20_contract_code() |> to_string() == contract_code do
      %{account_id: account_id}
      |> GodwokenIndexer.Worker.GenerateERC20SeriesContract.new()
      |> Oban.insert()
    end
  end
end
