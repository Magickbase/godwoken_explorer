defmodule GodwokenExplorer.Chain do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Counters.{AccountsCounter, AverageBlockTime}
  alias GodwokenExplorer.Chain.Cache.{BlockCount, TransactionCount}
  alias GodwokenExplorer.Chain.Hash

  @address_hash_len 40
  @tx_block_hash_len 64

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
      %Account{type: type, script_hash: script_hash}
      when type in [:polyjuice_contract, :meta_contract, :polyjuice_creator, :eth_addr_reg] ->
        incoming_transaction_count = address_to_incoming_transaction_count(script_hash)

        if incoming_transaction_count == 0 do
          total_transactions_sent_by_address(script_hash)
        else
          incoming_transaction_count
        end

      _ ->
        total_transactions_sent_by_address(account.script_hash)
    end
  end

  def address_to_incoming_transaction_count(script_hash) do
    with %Account{id: id} <- Repo.get_by(Account, script_hash: script_hash) do
      to_address_query =
        from(
          transaction in Transaction,
          where: transaction.to_account_id == ^id
        )

      Repo.aggregate(to_address_query, :count, :hash, timeout: :infinity)
    end
  end

  def total_transactions_sent_by_address(script_hash) do
    last_nonce =
      with %Account{id: id} <- Repo.get_by(Account, script_hash: script_hash) do
        id
        |> Transaction.last_nonce_by_address_query()
        |> Repo.one(timeout: :infinity)
      end

    case last_nonce do
      nil -> 0
      value -> value + 1
    end
  end

  def address_to_token_transfer_count(script_hash) do
    eth_address =
      case Repo.get_by(Account, script_hash: script_hash) do
        %Account{eth_address: eth_address} ->
          eth_address

        nil ->
          script_hash
      end

    udt_type? =
      from(u in UDT,
        join: a in Account,
        on: a.id == u.bridge_account_id,
        where: a.script_hash == ^script_hash
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
          where: token_transfer.to_address_hash == ^eth_address,
          or_where: token_transfer.from_address_hash == ^eth_address
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
        where: account.eth_address in ^hashes,
        select: account.eth_address
      )

    results = Repo.all(query)

    hashes
    |> Enum.map(fn hash ->
      result = results |> Enum.find(fn result -> hash in result end)

      script_hash =
        if is_nil(result) do
          nil
        else
          List.last(result)
        end

      %{hash: hash, script_hash: script_hash}
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
        where: a.eth_address == ^address_hash
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
        where: a.eth_address == ^address_hash
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

  @spec string_to_block_hash(String.t()) :: {:ok, Hash.t()} | :error
  def string_to_block_hash(string) when is_binary(string) do
    Hash.Full.cast(string)
  end

  def string_to_block_hash(_), do: :error

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

  @spec from_param(String.t()) ::
          {:ok, Address.t() | Block.t() | Transaction.t()} | {:error, :not_found}
  def from_param(param)

  def from_param("0x" <> number_string = param)
      when byte_size(number_string) == @address_hash_len,
      do: address_from_param(param)

  def from_param("0x" <> number_string = param)
      when byte_size(number_string) == @tx_block_hash_len,
      do: block_or_transaction_from_param(param)

  def from_param(param) when byte_size(param) == @address_hash_len,
    do: address_from_param("0x" <> param)

  def from_param(param) when byte_size(param) == @tx_block_hash_len,
    do: block_or_transaction_from_param("0x" <> param)

  def from_param(string) when is_binary(string) do
    case param_to_block_number(string) do
      {:ok, number} -> number_to_block(number)
      _ -> token_address_from_name(string)
    end
  end

  @spec number_to_block(Block.block_number(), []) ::
          {:ok, Block.t()} | {:error, :not_found}
  def number_to_block(number, options \\ []) when is_list(options) do
    Block
    |> where(number: ^number)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      block -> {:ok, block}
    end
  end

  def param_to_block_number(formatted_number) when is_binary(formatted_number) do
    case Integer.parse(formatted_number) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :invalid}
    end
  end

  defp address_from_param(param) do
    case string_to_address_hash(param) do
      {:ok, hash} ->
        case Account.search(hash) do
          nil ->
            {:error, :not_found}

          account ->
            {:ok, account}
        end

      :error ->
        {:error, :not_found}
    end
  end

  defp token_address_from_name(name) do
    query =
      from(udt in UDT,
        where: ilike(udt.symbol, ^name),
        or_where: ilike(udt.name, ^name)
      )

    query
    |> Repo.all()
    |> case do
      [] ->
        {:error, :not_found}

      udts ->
        if Enum.count(udts) == 1 do
          {:ok, List.first(udts)}
        else
          {:error, :not_found}
        end
    end
  end

  defp block_or_transaction_from_param(param) do
    with {:error, :not_found} <- transaction_from_param(param),
         {:error, :not_found} <- hash_string_to_block(param),
         {:error, :not_found} <- pending_transaction_from_param(param) do
      address_from_param(param)
    end
  end

  defp transaction_from_param(param) do
    case string_to_transaction_hash(param) do
      {:ok, hash} ->
        hash_to_transaction(hash)

      :error ->
        {:error, :not_found}
    end
  end

  defp pending_transaction_from_param(param) do
    case string_to_transaction_hash(param) do
      {:ok, hash} ->
        hash_to_pending_transaction(hash)

      :error ->
        {:error, :not_found}
    end
  end

  defp hash_string_to_block(hash_string) do
    case string_to_block_hash(hash_string) do
      {:ok, hash} ->
        hash_to_block(hash)

      :error ->
        {:error, :not_found}
    end
  end

  @spec hash_to_transaction(Hash.Full.t(), []) ::
          {:ok, Transaction.t()} | {:error, :not_found}
  def hash_to_transaction(
        %Hash{byte_count: unquote(Hash.Full.byte_count())} = hash,
        options \\ []
      )
      when is_list(options) do
    Transaction
    |> where([t], t.eth_hash == ^hash or t.hash == ^hash)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      transaction ->
        {:ok, transaction}
    end
  end

  @spec hash_to_pending_transaction(Hash.Full.t(), []) ::
          {:ok, PendingTransaction.t()} | {:error, :not_found}
  def hash_to_pending_transaction(
        %Hash{byte_count: unquote(Hash.Full.byte_count())} = hash,
        options \\ []
      )
      when is_list(options) do
    PendingTransaction
    |> where(hash: ^hash)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      transaction ->
        {:ok, transaction}
    end
  end

  @spec hash_to_block(Hash.Full.t(), []) ::
          {:ok, Block.t()} | {:error, :not_found}
  def hash_to_block(%Hash{byte_count: unquote(Hash.Full.byte_count())} = hash, options \\ [])
      when is_list(options) do
    Block
    |> where(hash: ^hash)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      block ->
        {:ok, block}
    end
  end

  defp boolean_to_check_result(true), do: :ok

  defp boolean_to_check_result(false), do: :not_found
end
