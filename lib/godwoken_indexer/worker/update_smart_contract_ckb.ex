defmodule GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB do
  @moduledoc """
  update smart contract ckb balance
  """
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.CurrentUDTBalance
  alias GodwokenExplorer.Chain.Hash.Address
  alias GodwokenExplorer.SmartContract
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Chain.Import

  import GodwokenRPC.Util, only: [import_timestamps: 0]
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"addresses" => addresses}}) do
    do_perform(addresses)
    :ok
  end

  def do_perform(addresses) do
    addresses =
      addresses
      |> Enum.map(fn address ->
        {:ok, result} = Address.cast(address)
        result
      end)

    q =
      from(a in Account,
        where: a.eth_address in ^addresses,
        join: s in SmartContract,
        on: s.account_id == a.id,
        select: %{s: s, id: a.id, address: a.eth_address}
      )

    result = Repo.all(q)
    addresses = result |> Enum.map(fn m -> m[:address] end)
    addresses_balance = CurrentUDTBalance.get_ckb_balance(addresses)

    need_update_map =
      addresses_balance
      |> Enum.map(fn %{balance: balance, address: address} ->
        %{
          s: s,
          id: id,
          address: _address
        } = Enum.find(result, fn m -> m[:address] == address end)

        %{
          s: s,
          id: id,
          balance: balance,
          address: address
        }
      end)
      |> Enum.map(fn %{s: s, balance: balance} ->
        s
        |> Map.from_struct()
        |> Map.merge(%{ckb_balance: balance})
      end)

    Import.insert_changes_list(need_update_map,
      for: SmartContract,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:ckb_balance, :updated_at]},
      conflict_target: :account_id
    )
  end
end
