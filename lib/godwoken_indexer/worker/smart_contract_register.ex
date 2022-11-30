# defmodule GodwokenExplorer.Graphql.Workers.SmartContractRegister do
defmodule GodwokenIndexer.Workers.SmartContractRegister do
  alias GodwokenIndexer.Workers.Sourcify, as: ObanSourcify

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract}

  import Ecto.Query

  use Oban.Worker, queue: :default
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    last_100_unregistered_polyjuice_contracts = get_unregistered_eth_addresses() |> Repo.all()

    # oban open community version, need insert one by one to avoid duplicate job
    Enum.chunk_every(last_100_unregistered_polyjuice_contracts, 10)
    |> Task.async_stream(fn accounts ->
      Enum.each(accounts, fn account ->
        account
        |> ObanSourcify.new()
        |> Oban.insert()
      end)
    end)

    :ok
  end

  def get_unregistered_eth_addresses() do
    from(a in Account)
    |> where([a], a.type == :polyjuice_contract)
    |> join(:left, [a], s in SmartContract, on: s.account_id == a.id)
    |> where([a, s], is_nil(s.account_id))
    |> order_by([a], desc: a.id)
    |> limit(100)
    |> select([a, s], %{eth_address: a.eth_address})
  end
end
