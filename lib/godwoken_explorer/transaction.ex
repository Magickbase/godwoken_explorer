defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Chain.Cache.Transactions

  @tx_limit 500_000
  @account_tx_limit 100_000

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field(:args, :binary)
    field(:from_account_id, :integer)
    field(:nonce, :integer)
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
      :block_number
    ])
    |> validate_required([
      :hash,
      :from_account_id,
      :to_account_id,
      :nonce,
      :args,
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
        list_tx_hash_by_transaction_query(true)
        |> order_by([t], desc: t.block_number, desc: t.inserted_at)
        |> limit(10)
        |> Repo.all()
        |> Enum.map(fn %{tx_hash: tx_hash} -> tx_hash end)
        |> list_transaction_by_tx_hash()
        |> Repo.all()
    end
  end

  def find_by_hash(hash) do
    case list_transaction_by_tx_hash([hash]) |> Repo.one() do
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

    query_a |> union_all(^query_b) |> Repo.all() |> Enum.count()
  end

  def count_of_account(%{type: type, account_id: account_id, eth_address: _eth_address})
      when type in [:meta_contract, :polyjuice_root, :polyjuice_contract] do
    from(t in Transaction, where: t.to_account_id == ^account_id) |> Repo.aggregate(:count)
  end

  def count_of_account(%{type: type, account_id: account_id, eth_address: _eth_address})
      when type == :udt do
    udt_id = UDT.get_contract_id(account_id)
    from(t in Transaction, where: t.to_account_id == ^udt_id) |> Repo.aggregate(:count)
  end

  @doc "udt transfer tx"
  def account_transactions_data(
        %{udt_account_id: udt_account_id},
        page
      ) do
    udt_id = UDT.get_contract_id(udt_account_id)

    tx_hashes =
      list_tx_hash_by_transaction_query(
        dynamic(
          [t, p],
          t.to_account_id == ^udt_id and not is_nil(p.transfer_count)
        )
      )
      |> order_by([t], desc: t.block_number, desc: t.inserted_at)
      |> limit(@account_tx_limit)

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{block_hash: block_hash},
        page
      ) do
    tx_hashes =
      list_tx_hash_by_transaction_query(dynamic([t], t.block_hash == ^block_hash))
      |> order_by([t], desc: t.block_number, desc: t.inserted_at)

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, udt_account_id: udt_account_id},
        page
      ) do
    query_a =
      list_tx_hash_by_transaction_query(
        dynamic([t], t.from_account_id == ^account_id and t.to_account_id == ^udt_account_id)
      )

    query_b =
      list_tx_hash_by_polyjuice_query(
        dynamic(
          [p, t],
          p.receive_eth_address == ^eth_address and t.to_account_id == ^udt_account_id and
            not is_nil(p.transfer_count)
        )
      )

    tx_hashes =
      from(q in subquery(query_a |> union_all(^query_b)),
        limit: @account_tx_limit,
        order_by: [desc: q.block_number, desc: q.inserted_at]
      )

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, contract_id: contract_id},
        page
      ) do
    query_a =
      list_tx_hash_by_transaction_query(
        dynamic([t], t.from_account_id == ^account_id and t.to_account_id == ^contract_id)
      )

    query_b =
      list_tx_hash_by_polyjuice_query(
        dynamic([p, t], p.receive_eth_address == ^eth_address and t.to_account_id == ^contract_id)
      )

    tx_hashes =
      from(q in subquery(query_a |> union_all(^query_b)),
        limit: @account_tx_limit,
        order_by: [desc: q.block_number, desc: q.inserted_at]
      )

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: _eth_address},
        page
      )
      when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] do
    tx_hashes =
      list_tx_hash_by_transaction_query(dynamic([t], t.to_account_id == ^account_id))
      |> order_by([t], desc: t.block_number, desc: t.inserted_at)
      |> limit(@account_tx_limit)

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: eth_address},
        page
      )
      when type == :user do
    query_a = list_tx_hash_by_transaction_query(dynamic([t], t.from_account_id == ^account_id))
    query_b = list_tx_hash_by_polyjuice_query(dynamic([p], p.receive_eth_address == ^eth_address))

    tx_hashes =
      from(q in subquery(query_a |> union_all(^query_b)),
        limit: @account_tx_limit,
        order_by: [desc: q.block_number, desc: q.inserted_at]
      )

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, erc20: true},
        page
      ) do
    udt_ids = UDT.get_udt_contract_ids()

    query_a =
      list_tx_hash_by_transaction_query(
        dynamic(
          [t, p],
          t.from_account_id == ^account_id and not is_nil(p.transfer_count) and
            t.to_account_id in ^udt_ids
        )
      )

    query_b =
      list_tx_hash_by_polyjuice_query(
        dynamic(
          [p, t],
          p.receive_eth_address == ^eth_address and not is_nil(p.transfer_count) and
            t.to_account_id in ^udt_ids
        )
      )

    tx_hashes =
      from(q in subquery(query_a |> union_all(^query_b)),
        limit: @account_tx_limit,
        order_by: [desc: q.block_number, desc: q.inserted_at]
      )

    parse_result(tx_hashes, page)
  end

  def account_transactions_data(page) do
    tx_hashes =
      list_tx_hash_by_transaction_query(true)
      |> order_by([t], desc: t.block_number, desc: t.inserted_at)
      |> limit(@tx_limit)

    parse_result(tx_hashes, page)
  end

  defp parse_result(tx_hashes, page) do
    tx_hashes_struct = Repo.paginate(tx_hashes, page: page)

    results =
      list_transaction_by_tx_hash(
        Enum.map(tx_hashes_struct.entries, fn %{tx_hash: tx_hash} -> tx_hash end)
      )
      |> order_by([t], desc: t.block_number, desc: t.inserted_at)
      |> Repo.all()

    parsed_result =
      Enum.map(results, fn record ->
        stringify_and_unix_maps(record)
        |> Map.merge(%{method: Polyjuice.get_method_name(record.to_account_id, record.input)})
        |> Map.drop([:input, :to_account_id])
      end)

    %{
      page: page,
      total_count: tx_hashes_struct.total_entries,
      txs: parsed_result
    }
  end

  def list_tx_hash_by_transaction_query(condition) do
    from(t in Transaction,
      left_join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      select: %{tx_hash: t.hash, block_number: t.block_number, inserted_at: t.inserted_at},
      where: ^condition
    )
  end

  def list_tx_hash_by_polyjuice_query(condition) do
    from(p in Polyjuice,
      join: t in Transaction,
      on: t.hash == p.tx_hash,
      select: %{tx_hash: p.tx_hash, block_number: t.block_number, inserted_at: t.inserted_at},
      where: ^condition
    )
  end

  def list_transaction_by_tx_hash(hashes) do
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
      left_join: u7 in UDT,
      on: u7.bridge_account_id == s4.account_id,
      where: t.hash in ^hashes,
      select: %{
        hash: t.hash,
        block_hash: b.hash,
        block_number: b.number,
        l1_block_number: b.layer1_block_number,
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
        status: b.status,
        polyjuice_status: p.status,
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
        udt_symbol: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u6, u7.symbol, u6.symbol),
        udt_icon: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u6, u7.icon, u6.icon),
        input: p.input,
        to_account_id: t.to_account_id
      }
    )
  end
end
