defmodule GodwokenIndexer.Worker.ImportContractCode do
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.{Repo, Account}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"block_number" => block_number, "address" => address}}) do
    {:ok,
     %{
       errors: [],
       params_list: [
         %{address: address, code: contract_code}
       ]
     }} = GodwokenRPC.fetch_codes([%{block_quantity: block_number, address: address}])

    case Account.search(address) do
      %Account{} = account ->
        account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()

      nil ->
        {:ok, account} = Account.find_or_create_contract_by_eth_address(address)
        account |> Account.changeset(%{contract_code: contract_code}) |> Repo.update()
    end

    :ok
  end
end
