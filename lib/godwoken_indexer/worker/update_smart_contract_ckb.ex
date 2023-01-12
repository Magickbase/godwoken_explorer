defmodule GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB do
  @moduledoc """
  update smart contract ckb balance
  """
  use Oban.Worker, queue: :default
  require Logger

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.CurrentUDTBalance
  alias GodwokenExplorer.Chain.Hash.Address
  alias GodwokenExplorer.SmartContract
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.UDT
  alias GodwokenExplorer.Chain.Import
  alias GodwokenExplorer.Chain.Hash.Full

  alias GodwokenExplorer.Chain.Hash.Address

  import GodwokenRPC.Util, only: [import_timestamps: 0]
  import Ecto.Query

  @type address() :: Address.t()

  @spec new_job(list(address())) ::
          {:ok, Oban.Job.t()} | {:error, Oban.Job.changeset() | term} | :ok
  def new_job(addresses) when is_list(addresses) do
    q =
      from(a in Account,
        where: a.eth_address in ^addresses,
        join: s in SmartContract,
        on: s.account_id == a.id,
        select: fragment("'0x' || encode(?, 'hex')", a.eth_address)
      )

    addresses = Repo.all(q)

    if length(addresses) > 0 do
      %{addresses: addresses}
      |> __MODULE__.new()
      |> Oban.insert()
    else
      :ok
    end
  end

  @spec update_smart_contract_with_ckb_balance(list(map())) :: {:ok, term()}
  def update_smart_contract_with_ckb_balance(params) when is_list(params) do
    [ckb_bridged_address, ckb_contract_address] =
      UDT.ckb_account_id() |> UDT.list_address_by_udt_id()

    ckb_bridged_address = ckb_bridged_address

    addresses =
      params
      |> Enum.filter(fn p ->
        if not is_nil(p[:token_contract_address_hash]) do
          {:ok, token_contract_address_hash} = Address.cast(p[:token_contract_address_hash])
          token_contract_address_hash == ckb_contract_address
        else
          if not is_nil(p[:udt_script_hash]) do
            {:ok, udt_script_hash} = Full.cast(p[:udt_script_hash])
            udt_script_hash == ckb_bridged_address
          else
            false
          end
        end
      end)
      |> Enum.map(fn m -> m[:address_hash] end)
      |> Enum.filter(&(not is_nil(&1)))

    q =
      from(a in Account,
        where: a.eth_address in ^addresses,
        join: s in SmartContract,
        on: s.account_id == a.id,
        select: %{s: s, address_hash: a.eth_address}
      )

    res = Repo.all(q)

    need_update_map =
      res
      |> Enum.map(fn %{address_hash: address_hash, s: s} ->
        case Enum.find(params, fn m ->
               m[:address_hash] == address_hash and not is_nil(m[:value])
             end) do
          %{address_hash: ^address_hash, value: value} ->
            s
            |> Map.from_struct()
            |> Map.merge(%{ckb_balance: value})

          _ ->
            :skip
        end
      end)
      |> Enum.filter(&(&1 != :skip))

    Import.insert_changes_list(need_update_map,
      for: SmartContract,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:ckb_balance, :updated_at]},
      conflict_target: :account_id
    )
  end

  def trigger_update_all_smart_contracts_ckbs(inspect \\ false) do
    q =
      from(a in Account,
        join: s in SmartContract,
        on: s.account_id == a.id,
        select: fragment("'0x' || encode(?, 'hex')", a.eth_address)
      )

    addresses = Repo.all(q)

    if inspect do
      length(addresses) |> IO.inspect(label: "need process jobs: ")
    end

    addresses
    |> Enum.chunk_every(100)
    |> Enum.reduce(0, fn addresses, acc ->
      if inspect do
        IO.inspect(label: "starting: #{acc}")
      end

      do_perform(addresses)
      res = acc + length(addresses)

      if inspect do
        IO.inspect(label: "finished: #{res}")
      end

      res
    end)
  end

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
