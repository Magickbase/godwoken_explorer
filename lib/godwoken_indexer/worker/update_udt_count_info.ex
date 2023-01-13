defmodule GodwokenIndexer.Worker.UpdateUDTCountInfo do
  @moduledoc """
  Fetch udt's meta and update.
  """
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Chain.Hash.{Address}
  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.UDT
  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.Chain.Import

  import Ecto.Query
  import GodwokenRPC.Util, only: [import_timestamps: 0]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "update_created_addresses" => update_created_addresses,
          "update_burnt_addresses" => update_burnt_addresses
        }
      }) do
    do_perform(update_created_addresses, update_burnt_addresses)
    :ok
  end

  def trigger_process_erc721_udts(inspect \\ false) do
    from(u in UDT, where: u.eth_type == :erc721)
    |> Repo.all()
    |> Enum.chunk_every(100)
    |> Enum.reduce(0, fn chunk, acc ->
      if inspect do
        IO.inspect("starting erc721 udts created/burnt: #{acc}")
      end

      update_created_addresses = chunk |> Enum.map(fn u -> u.contract_address_hash end)
      update_burnt_addresses = update_created_addresses
      do_perform(update_created_addresses, update_burnt_addresses)

      res = acc + length(chunk)

      if inspect do
        IO.inspect("finish erc721 udts created/burnt: #{res}")
      end

      res
    end)
  end

  def new_job(log_parse_token_transfers) do
    minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

    log_parse_token_transfers =
      log_parse_token_transfers
      |> Enum.filter(fn t -> t.token_type == :erc721 end)

    update_created_addresses =
      log_parse_token_transfers
      |> Enum.filter(fn t -> t.from_address_hash == minted_burn_address_hash end)
      |> Enum.map(fn t -> t.token_contract_address_hash end)
      |> Enum.uniq()

    update_burnt_addresses =
      log_parse_token_transfers
      |> Enum.filter(fn t -> t.to_address_hash == minted_burn_address_hash end)
      |> Enum.map(fn t -> t.token_contract_address_hash end)
      |> Enum.uniq()

    if length(update_created_addresses) + length(update_burnt_addresses) > 0 do
      %{
        "update_created_addresses" => update_created_addresses,
        "update_burnt_addresses" => update_burnt_addresses
      }
      |> __MODULE__.new()
      |> Oban.insert()
    else
      :ok
    end
  end

  def do_perform(update_created_addresses, update_burnt_addresses) do
    update_created_addresses = type_cast(update_created_addresses) |> filter_erc721_address()

    update_burnt_addresses = type_cast(update_burnt_addresses) |> filter_erc721_address()

    minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

    created_counts =
      from(tt in TokenTransfer)
      |> where([tt], tt.token_contract_address_hash in ^update_created_addresses)
      |> where([tt], tt.from_address_hash == ^minted_burn_address_hash)
      |> group_by([tt], tt.token_contract_address_hash)
      |> select([tt], %{
        contract_address_hash: tt.token_contract_address_hash,
        created_count: count(tt.token_id)
      })
      |> Repo.all()
      |> process_udt(:created)

    burned_counts =
      from(tt in TokenTransfer)
      |> where([tt], tt.token_contract_address_hash in ^update_burnt_addresses)
      |> where([tt], tt.to_address_hash == ^minted_burn_address_hash)
      |> group_by([tt], tt.token_contract_address_hash)
      |> select([tt, u], %{
        contract_address_hash: tt.token_contract_address_hash,
        burnt_count: count(tt.token_id)
      })
      |> Repo.all()
      |> process_udt(:burnt)

    Import.insert_changes_list(
      created_counts,
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:created_count, :updated_at]},
      conflict_target: :contract_address_hash
    )

    Import.insert_changes_list(
      burned_counts,
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:burnt_count, :updated_at]},
      conflict_target: :contract_address_hash
    )

    :ok
  end

  defp process_udt(lx, created_or_burnt) when created_or_burnt in [:created, :burnt] do
    contract_address_hashes =
      lx
      |> Enum.map(& &1.contract_address_hash)

    from(u in UDT,
      where: u.contract_address_hash in ^contract_address_hashes
    )
    |> Repo.all()
    |> Enum.map(fn udt ->
      if created_or_burnt == :created do
        %{created_count: created_count} =
          Enum.find(lx, fn x -> x.contract_address_hash == udt.contract_address_hash end)

        udt
        |> Map.from_struct()
        |> Map.merge(%{created_count: created_count})
      else
        %{burnt_count: burnt_count} =
          Enum.find(lx, fn x -> x.contract_address_hash == udt.contract_address_hash end)

        udt
        |> Map.from_struct()
        |> Map.merge(%{burnt_count: burnt_count})
      end
    end)
  end

  defp type_cast(lx, cast_module \\ Address) when is_list(lx) do
    lx
    |> Enum.map(fn address ->
      {:ok, address} = cast_module.cast(address)
      address
    end)
  end

  defp filter_erc721_address(lx) do
    from(u in UDT,
      where:
        u.contract_address_hash in ^lx and
          u.eth_type in [:erc721],
      select: u.contract_address_hash
    )
    |> Repo.all()
  end
end
