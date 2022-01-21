defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Chain.Cache.Transactions

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field(:args, :binary)
    field(:from_account_id, :integer)
    field(:nonce, :integer)
    field(:status, Ecto.Enum, values: [:committed, :finalized], default: :committed)
    field(:to_account_id, :integer)
    field(:type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice])
    field(:block_number, :integer)
    field(:block_hash, :binary)

    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, define_field: false)

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :hash,
      :block_hash,
      :type,
      :from_account_id,
      :to_account_id,
      :nonce,
      :args,
      :status,
      :block_number
    ])
    |> validate_required([
      :hash,
      :from_account_id,
      :to_account_id,
      :nonce,
      :args,
      :status,
      :block_number
    ])
  end

  def create_transaction(%{type: :sudt} = attrs) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
      |> Repo.insert(on_conflict: :nothing)

    UDTTransfer.create_udt_transfer(attrs)
    transaction
  end

  def create_transaction(%{type: :polyjuice_creator} = attrs) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
      |> Repo.insert(on_conflict: :nothing)

    PolyjuiceCreator.create_polyjuice_creator(attrs)
    transaction
  end

  def create_transaction(%{type: :polyjuice} = attrs) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Repo.insert(on_conflict: :nothing)

    Polyjuice.create_polyjuice(attrs)
    transaction
  end

  # TODO: from and to may can refactor to be a single method
  def latest_10_records do
    case Transactions.all() do
      txs when is_list(txs) and length(txs) == 10 ->
        txs
        |> Enum.map(fn t ->
          t
          |> Map.take([:hash, :from, :to, :to_alias, :type])
          |> Map.merge(%{timestamp: t.block.inserted_at})
        end)

      _ ->
        list_by_account_transaction_query(true)
        |> order_by([t], desc: t.block_number, desc: t.inserted_at)
        |> limit(10)
        |> Repo.all()
    end
  end

  def find_by_hash(hash) do
    case list_by_account_transaction_query(dynamic([t], t.hash == ^hash)) |> Repo.one() do
      nil ->
        nil

      tx ->
        cond do
          tx.type == :polyjuice_creator ->
            creator = Repo.get_by(PolyjuiceCreator, tx_hash: tx.hash) |> Repo.preload(:udt)

            tx
            |> Map.merge(%{
              code_hash: creator.code_hash,
              hash_type: creator.hash_type,
              script_args: creator.script_args,
              fee_amount: creator.fee_amount,
              fee_udt: creator.udt.name
            })

          true ->
            contract = Repo.get_by(SmartContract, account_id: tx.to_account_id)

            tx
            |> Map.merge(%{
              contract_abi: contract && contract.abi
            })
        end
        |> stringify_and_unix_maps()
        |> Map.drop([:to_account_id])
    end
  end

  def count_of_account(%{
        type: type,
        account_id: account_id,
        eth_address: eth_address
      })
      when type == :user do
    query_a =
      from(t in Transaction,
        where: t.from_account_id == ^account_id,
        select: t.hash
      )

    query_b =
      from(p in Polyjuice,
        where: p.receive_eth_address == ^eth_address,
        select: p.tx_hash
      )

    query_a |> union(^query_b) |> Repo.all() |> Enum.count()
  end

  def count_of_account(%{type: type, account_id: account_id, eth_address: _eth_address})
      when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] do
    from(t in Transaction, where: t.to_account_id == ^account_id) |> Repo.aggregate(:count)
  end

  @doc "udt transfer tx"
  def account_transactions_data(
        %{udt_account_id: udt_account_id},
        page
      ) do
    txs =
      list_by_account_transaction_query(
        dynamic(
          [t, b1, a2, a3, s4, p5],
          t.to_account_id == ^udt_account_id and not is_nil(p5.transfer_count)
        )
      )
      |> order_by([t], desc: t.inserted_at)

    parse_result(txs, page)
  end

  def account_transactions_data(
        %{block_hash: block_hash},
        page
      ) do
    txs =
      list_by_account_transaction_query(dynamic([t], t.block_hash == ^block_hash))
      |> order_by([t], desc: t.inserted_at)

    parse_result(txs, page)
  end

  def account_transactions_data(
      %{account_id: account_id, eth_address: eth_address, udt_account_id: udt_account_id},
        page
      ) do
    query_a =
      list_by_account_transaction_query(
        dynamic([t], t.from_account_id == ^account_id and t.to_account_id == ^udt_account_id )
      )

    query_b =
      list_by_account_polyjuice_query(
        dynamic([p, t], p.receive_eth_address == ^eth_address and t.to_account_id == ^udt_account_id and not is_nil(p.transfer_count))
      )

    txs = from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])

    parse_result(txs, page)
  end

  def account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, contract_id: contract_id},
        page
      ) do
    query_a =
      list_by_account_transaction_query(
        dynamic([t], t.from_account_id == ^account_id and t.to_account_id == ^contract_id)
      )

    query_b =
      list_by_account_polyjuice_query(
        dynamic([p, t], p.receive_eth_address == ^eth_address and t.to_account_id == ^contract_id)
      )

    txs = from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])

    parse_result(txs, page)
  end

  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: _eth_address},
        page
      )
      when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] do
    txs =
      list_by_account_transaction_query(dynamic([t], t.to_account_id == ^account_id))
      |> order_by([t], [desc: t.block_number, desc: t.inserted_at])

    parse_result(txs, page)
  end

  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: eth_address},
        page
      )
      when type == :user do
    query_a = list_by_account_transaction_query(dynamic([t], t.from_account_id == ^account_id))
    query_b = list_by_account_polyjuice_query(dynamic([p], p.receive_eth_address == ^eth_address))

    txs = from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])

    parse_result(txs, page)
  end

  def account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, erc20: true},
        page
      ) do
    udt_ids = from(u in UDT, select: u.id) |> Repo.all()
    query_a = list_by_account_transaction_query(dynamic([t, b, a2, a3, s4, p], t.from_account_id == ^account_id and not(is_nil(p.transfer_count)) and t.to_account_id in ^udt_ids))
    query_b = list_by_account_polyjuice_query(dynamic([p, t], p.receive_eth_address == ^eth_address and not(is_nil(p.transfer_count)) and t.to_account_id in ^udt_ids))

    txs = from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])

    parse_result(txs, page)
  end

  def account_transactions_data(page) do
    txs =
      list_by_account_transaction_query(true)
      |> order_by([t], desc: t.inserted_at)

    parse_result(txs, page)
  end

  defp parse_result(txs, page) do
    original_struct = Repo.paginate(txs, page: page)

    parsed_result =
      Enum.map(original_struct.entries, fn record ->
        stringify_and_unix_maps(record)
        |> Map.merge(%{method: Polyjuice.get_method_name(record.to_account_id, record.input)})
        |> Map.drop([:input, :to_account_id])
      end)

    %{
      page: Integer.to_string(original_struct.page_number),
      total_count: Integer.to_string(original_struct.total_entries),
      txs: parsed_result
    }
  end

  defp list_by_account_transaction_query(condition) do
    from(t in Transaction,
      join: b in Block,
      on: [hash: t.block_hash],
      join: a2 in Account,
      on: a2.id == t.from_account_id,
      join: a3 in Account,
      on: a3.id == t.to_account_id,
      left_join: s4 in SmartContract,
      on: s4.account_id == t.to_account_id,
      left_join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      left_join: u6 in UDT,
      on: u6.id == s4.account_id,
      where: ^condition,
      select: %{
        hash: t.hash,
        block_hash: b.hash,
        block_number: b.number,
        l1_block_number: b.layer1_block_number,
        timestamp: b.timestamp,
        from: a2.eth_address,
        to: fragment("
          CASE WHEN ? = 'user' THEN encode(?, 'escape')
           ELSE encode(?, 'escape') END", a3.type, a3.eth_address, a3.short_address),
        to_alias:
          fragment(
            "
          CASE WHEN ? = 'user' THEN encode(?, 'escape')
          WHEN ? = 'udt' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE encode(?, 'escape') END)
          WHEN ? = 'polyjuice_contract' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE encode(?, 'escape') END)
          WHEN ? = 'polyjuice_creator' THEN 'Deploy Contract'
          ELSE encode(?, 'escape') END",
            a3.type,
            a3.eth_address,
            a3.type,
            s4.name,
            s4.name,
            a3.short_address,
            a3.type,
            s4.name,
            s4.name,
            a3.short_address,
            a3.type,
            a3.short_address
          ),
        status: t.status,
        type: t.type,
        nonce: t.nonce,
        inserted_at: t.inserted_at,
        fee: p.gas_price * p.gas_used,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        value: p.value,
        receive_eth_address: p.receive_eth_address,
        transfer_value: p.transfer_count,
        transfer_count: p.transfer_count,
        udt_id: s4.account_id,
        udt_symbol: u6.symbol,
        udt_icon: u6.icon,
        input: p.input,
        to_account_id: t.to_account_id
      }
    )
  end

  defp list_by_account_polyjuice_query(condition) do
    from(p in Polyjuice,
      join: t in Transaction,
      on: t.hash == p.tx_hash,
      join: b in Block,
      on: b.hash == t.block_hash,
      join: a3 in Account,
      on: a3.id == t.from_account_id,
      join: a4 in Account,
      on: a4.id == t.to_account_id,
      left_join: s5 in SmartContract,
      on: s5.account_id == t.to_account_id,
      left_join: u6 in UDT,
      on: u6.id == s5.account_id,
      where: ^condition,
      select: %{
        hash: p.tx_hash,
        block_hash: b.hash,
        block_number: b.number,
        l1_block_number: b.layer1_block_number,
        timestamp: b.timestamp,
        from: a3.eth_address,
        to: fragment("
          CASE WHEN a4.type = 'user' THEN encode(a4.eth_address, 'escape')
           ELSE encode(a4.short_address, 'escape') END"),
        to_alias: fragment("
          CASE WHEN a4.type = 'user' THEN encode(a4.eth_address, 'escape')
          WHEN a4.type = 'udt' THEN (CASE WHEN s5.name IS NOT NULL THEN s5.name ELSE encode(a4.short_address, 'escape') END)
          WHEN a4.type = 'polyjuice_contract' THEN (CASE WHEN s5.name IS NOT NULL THEN s5.name ELSE encode(a4.short_address, 'escape') END)
          WHEN a4.type = 'polyjuice_creator' THEN 'Deploy Contract'
          ELSE encode(a4.short_address, 'escape') END"),
        status: t.status,
        type: t.type,
        nonce: t.nonce,
        insertetd_at: t.inserted_at,
        fee: p.gas_price * p.gas_used,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        value: p.value,
        receive_eth_address: p.receive_eth_address,
        transfer_value: p.transfer_count,
        transfer_count: p.transfer_count,
        udt_id: s5.account_id,
        udt_symbol: u6.symbol,
        udt_icon: u6.icon,
        input: p.input,
        to_account_id: t.to_account_id
      }
    )
  end
end
