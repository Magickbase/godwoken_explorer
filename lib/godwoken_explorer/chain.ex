defmodule GodwokenExplorer.Chain do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Counters.{AccountsCounter, AverageBlockTime}
  alias GodwokenExplorer.Chain.Cache.{BlockCount, TransactionCount}

  def extract_db_name(db_url) do
    if db_url == nil do
      ""
    else
      db_url
      |> String.split("/")
      |> Enum.take(-1)
      |> Enum.at(0)
    end
  end

  def extract_db_host(db_url) do
    if db_url == nil do
      ""
    else
      db_url
      |> String.split("@")
      |> Enum.take(-1)
      |> Enum.at(0)
      |> String.split(":")
      |> Enum.at(0)
    end
  end

  def address_to_transaction_count(account) do
    case account do
      %Account{type: type, short_address: short_address}
      when type in [:polyjuice_contract, :meta_contract, :polyjuice_creator, :eth_addr_reg] ->
        incoming_transaction_count = address_to_incoming_transaction_count(short_address)

        if incoming_transaction_count == 0 do
          total_transactions_sent_by_address(short_address)
        else
          incoming_transaction_count
        end

      _ ->
        total_transactions_sent_by_address(account.short_address)
    end
  end

  def address_to_incoming_transaction_count(short_address) do
    with %Account{id: id} <- Repo.get_by(Account, short_address: short_address) do
      to_address_query =
        from(
          transaction in Transaction,
          where: transaction.to_account_id == ^id
        )

      Repo.aggregate(to_address_query, :count, :hash, timeout: :infinity)
    end
  end

  def total_transactions_sent_by_address(short_address) do
    last_nonce =
      with %Account{id: id} <- Repo.get_by(Account, short_address: short_address) do
        id
        |> Transaction.last_nonce_by_address_query()
        |> Repo.one(timeout: :infinity)
      end

    case last_nonce do
      nil -> 0
      value -> value + 1
    end
  end

  def address_to_token_transfer_count(short_address) do
    %Account{eth_address: eth_address} = Repo.get_by(Account, short_address: short_address)

    udt_type? =
      from(u in UDT,
        join: a in Account,
        on: a.id == u.bridge_account_id,
        where: a.short_address == ^short_address
      )
      |> Repo.exists?()

    query =
      if udt_type? do
        from(
          token_transfer in TokenTransfer,
          where: token_transfer.token_contract_address_hash == ^eth_address
        )
      else
        from(
          token_transfer in TokenTransfer,
          where: token_transfer.to_address_hash == ^(eth_address || short_address),
          or_where: token_transfer.from_address_hash == ^(eth_address || short_address)
        )
      end

    Repo.aggregate(query, :count, timeout: :infinity)
  end

  def account_estimated_count do
    cached_value = AccountsCounter.fetch()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[count]]} =
        Repo.query!("SELECT reltuples FROM pg_class WHERE relname = 'accounts';")

      count
    else
      cached_value
    end
  end

  @spec block_estimated_count() :: non_neg_integer()
  def block_estimated_count do
    cached_value = BlockCount.get_count()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[count]]} =
        Repo.query!("SELECT reltuples FROM pg_class WHERE relname = 'blocks';")

      trunc(count)
    else
      cached_value
    end
  end

  @spec transaction_estimated_count() :: non_neg_integer()
  def transaction_estimated_count do
    cached_value = TransactionCount.get_count()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[rows]]} =
        Repo.query!(
          "SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname='transactions'"
        )

      trunc(rows)
    else
      cached_value
    end
  end

  def home_api_data(blocks, txs) do
    %{
      block_list:
        blocks
        |> Enum.map(fn record ->
          stringify_and_unix_maps(record)
        end),
      tx_list:
        txs
        |> Enum.map(fn record ->
          stringify_and_unix_maps(record)
        end),
      statistic: %{
        account_count: Integer.to_string(account_estimated_count()),
        block_count: ((blocks |> List.first() |> Map.get(:number)) + 1) |> Integer.to_string(),
        tx_count: Integer.to_string(transaction_estimated_count()),
        tps: Float.to_string(Block.transactions_count_per_second()),
        average_block_time: AverageBlockTime.average_block_time() |> Timex.Duration.to_seconds()
      }
    }
  end
end
