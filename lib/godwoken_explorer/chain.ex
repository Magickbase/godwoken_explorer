defmodule GodwokenExplorer.Chain do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Counters.{AccountsCounter, AverageBlockTime}
  alias GodwokenExplorer.Chain.Cache.{BlockCount, TransactionCount}
  alias GodwokenExplorer.Chain.Hash

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
      when type in [:polyjuice_contract, :meta_contract, :polyjuice_root] ->
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
          where: token_transfer.token_contract_address_hash == ^short_address
        )
      else
        from(
          token_transfer in TokenTransfer,
          where: token_transfer.to_address_hash == ^short_address,
          or_where: token_transfer.from_address_hash == ^short_address
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

  @spec string_to_address_hash(String.t()) :: {:ok, Hash.Address.t()} | :error
  def string_to_address_hash(string) when is_binary(string) do
    Hash.Address.cast(string)
  end

  def string_to_address_hash(_), do: :error

  def hashes_to_addresses(hashes) when is_list(hashes) do
    query =
      from(
        account in Account,
        where: account.short_address in ^hashes or account.eth_address in ^hashes,
        select: [account.eth_address, account.short_address]
      )

    results = Repo.all(query)

    hashes
    |> Enum.map(fn hash ->
      result = results |> Enum.find(fn result -> hash in result end)

      short_address =
        if is_nil(result) do
          nil
        else
          List.last(result)
        end

      %{hash: hash, short_address: short_address}
    end)
  end

  @spec check_address_exists(Hash.Address.t()) :: :ok | :not_found
  def check_address_exists(address_hash) do
    address_hash
    |> address_exists?()
    |> boolean_to_check_result()
  end

  @spec address_exists?(Hash.Address.t()) :: boolean()
  def address_exists?(address_hash) do
    query =
      from(
        a in Account,
        where: a.eth_address == ^address_hash or a.short_address == ^address_hash
      )

    Repo.exists?(query)
  end

  @spec address_hash_to_smart_contract(Hash.Address.t()) :: SmartContract.t() | nil
  def address_hash_to_smart_contract(address_hash) do
    query =
      from(
        smart_contract in SmartContract,
        join: a in Account,
        on: a.id == smart_contract.account_id,
        where: a.short_address == ^address_hash
      )

    current_smart_contract = Repo.one(query)

    if current_smart_contract do
      current_smart_contract
    else
      nil
    end
  end

  @spec string_to_transaction_hash(String.t()) :: {:ok, Hash.t()} | :error
  def string_to_transaction_hash(string) when is_binary(string) do
    Hash.Full.cast(string)
  end

  def string_to_transaction_hash(_), do: :error

  def param_to_block_timestamp(timestamp_string) when is_binary(timestamp_string) do
    case Integer.parse(timestamp_string) do
      {temstamp_int, ""} ->
        timestamp =
          temstamp_int
          |> DateTime.from_unix!(:second)

        {:ok, timestamp}

      _ ->
        {:error, :invalid_timestamp}
    end
  end

  def param_to_block_closest(closest) when is_binary(closest) do
    case closest do
      "before" -> {:ok, :before}
      "after" -> {:ok, :after}
      _ -> {:error, :invalid_closest}
    end
  end

  def timestamp_to_block_number(given_timestamp, closest) do
    {:ok, t} = Timex.format(given_timestamp, "%Y-%m-%d %H:%M:%S", :strftime)

    inner_query =
      from(
        block in Block,
        where:
          fragment(
            "? <= TO_TIMESTAMP(?, 'YYYY-MM-DD HH24:MI:SS') + (1 * interval '1 minute')",
            block.timestamp,
            ^t
          ),
        where:
          fragment(
            "? >= TO_TIMESTAMP(?, 'YYYY-MM-DD HH24:MI:SS') - (1 * interval '1 minute')",
            block.timestamp,
            ^t
          )
      )

    query =
      from(
        block in subquery(inner_query),
        select: block,
        order_by:
          fragment(
            "abs(extract(epoch from (? - TO_TIMESTAMP(?, 'YYYY-MM-DD HH24:MI:SS'))))",
            block.timestamp,
            ^t
          ),
        limit: 1
      )

    response = query |> Repo.one()

    response
    |> case do
      nil ->
        {:error, :not_found}

      %{:number => number, :timestamp => timestamp} ->
        block_number =
          get_block_number_based_on_closest(closest, timestamp, given_timestamp, number)

        {:ok, block_number}
    end
  end

  defp get_block_number_based_on_closest(closest, timestamp, given_timestamp, number) do
    case closest do
      :before ->
        if DateTime.compare(timestamp, given_timestamp) == :lt ||
             DateTime.compare(timestamp, given_timestamp) == :eq do
          number
        else
          number - 1
        end

      :after ->
        if DateTime.compare(timestamp, given_timestamp) == :lt ||
             DateTime.compare(timestamp, given_timestamp) == :eq do
          number + 1
        else
          number
        end
    end
  end

  @spec max_consensus_block_number() :: {:ok, Block.block_number()} | {:error, :not_found}
  def max_consensus_block_number do
    Block
    |> Repo.aggregate(:max, :number)
    |> case do
      nil -> {:error, :not_found}
      number -> {:ok, number}
    end
  end

  def token_from_address_hash(%Hash{byte_count: unquote(Hash.Address.byte_count())} = hash) do
    with %Account{id: id} <- Account.search(hash),
         %UDT{supply: supply} <-
           UDT |> where([u], u.id == ^id or u.bridge_account_id == ^id) |> Repo.one() do
      {:ok, supply}
    else
      _ -> {:error, :not_found}
    end
  end

  defp boolean_to_check_result(true), do: :ok

  defp boolean_to_check_result(false), do: :not_found
end
