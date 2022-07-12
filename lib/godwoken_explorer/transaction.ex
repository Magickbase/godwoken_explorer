defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Chain.Cache.Transactions
  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.Chain.{Hash, Data}

  @export_limit 5_000
  @tx_limit 500_000
  @account_tx_limit 100_000

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:hash, Hash.Full, autogenerate: false}
  schema "transactions" do
    field(:args, Data)
    field(:nonce, :integer)

    field(:type, Ecto.Enum, values: [:polyjuice_creator, :polyjuice, :eth_address_registry])

    field(:block_number, :integer)
    field(:eth_hash, Hash.Full)
    field(:index, :integer)

    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, type: Hash.Full)

    belongs_to(
      :from_account,
      Account,
      foreign_key: :from_account_id,
      references: :id,
      type: :integer
    )

    belongs_to(
      :to_account,
      Account,
      foreign_key: :to_account_id,
      references: :id,
      type: :integer
    )

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
      :block_number,
      :eth_hash,
      :index
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

  def last_nonce_by_address_query(account_id) do
    from(
      t in Transaction,
      select: t.nonce,
      where: t.from_account_id == ^account_id,
      order_by: [desc: :block_number],
      limit: 1
    )
  end

  def create_transaction(%{type: type} = attrs) when type in [:eth_address_registry] do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Repo.insert(on_conflict: :nothing)

    transaction
  end

  # TODO: from and to may can refactor to be a single method
  def latest_10_records do
    case Transactions.all() do
      txs when is_list(txs) and length(txs) == 10 ->
        txs
        |> Enum.map(fn t ->
          t
          |> Map.take([:hash, :from, :to, :to_alias, :type, :timestamp])
        end)

      _ ->
        case from(b in Block,
               where: b.transaction_count >= 10,
               order_by: [desc: b.number],
               limit: 1
             )
             |> Repo.one() do
          %Block{number: number} ->
            list_tx_hash_by_transaction_query(dynamic([t], t.block_number >= ^number))

          nil ->
            list_tx_hash_by_transaction_query(true)
        end
        |> limit(10)
        |> Repo.all()
        |> list_home_transaction_by_tx_hash()
        |> order_by([t], desc: t.block_number, desc: t.index)
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
            creator = Repo.get_by(PolyjuiceCreator, tx_hash: tx.hash)

            tx
            |> Map.merge(%{
              code_hash: creator.code_hash,
              hash_type: creator.hash_type,
              script_args: creator.script_args,
              fee_amount: creator.fee_amount
            })

          tx.type == :polyjuice ->
            contract = Repo.get_by(SmartContract, account_id: tx.to_account_id)

            tx
            |> Map.merge(%{
              contract_abi: contract && contract.abi
            })

          true ->
            tx
        end
        |> stringify_and_unix_maps()
        |> Map.drop([:to_account_id])
    end
  end

  def count_of_account(%{
        type: type,
        account_id: account_id
      })
      when type in [:eth_user] do
    from(t in Transaction,
      where: t.from_account_id == ^account_id,
      select: t.hash
    )
    |> Repo.aggregate(:count)
  end

  def count_of_account(%{type: type, account_id: account_id})
      when type in [:meta_contract, :polyjuice_creator, :polyjuice_contract, :udt] do
    from(t in Transaction, where: t.to_account_id == ^account_id) |> Repo.aggregate(:count)
  end

  def account_transactions_data(
        %{block_hash: block_hash},
        paging_options
      ) do
    tx_hashes = list_tx_hash_by_transaction_query(dynamic([t], t.block_hash == ^block_hash))

    parse_result(tx_hashes, paging_options)
  end

  def account_transactions_data(
        %{account: account, contract: contract},
        paging_options
      ) do
    tx_hashes =
      list_tx_hash_by_transaction_query(
        dynamic([t], t.from_account_id == ^account.id and t.to_account_id == ^contract.id)
      )
      |> limit(@account_tx_limit)

    parse_result(tx_hashes, paging_options)
  end

  def account_transactions_data(
        %{type: type, account: account},
        paging_options
      )
      when type in [:meta_contract, :udt, :polyjuice_creator, :polyjuice_contract, :eth_addr_reg] do
    condition = dynamic([t], t.to_account_id == ^account.id)

    paging_options =
      if (account.transaction_count || 0) > @account_tx_limit do
        paging_options |> Map.merge(%{options: [total_entries: @account_tx_limit]})
      else
        paging_options
      end

    tx_hashes =
      list_tx_hash_by_transaction_query(condition)
      |> limit(@account_tx_limit)

    parse_result(tx_hashes, paging_options)
  end

  def account_transactions_data(
        %{type: type, account: account},
        paging_options
      )
      when type in [:eth_user] do
    condition = dynamic([t], t.from_account_id == ^account.id)

    paging_options =
      if (account.transaction_count || 0) > @account_tx_limit do
        paging_options |> Map.merge(%{options: [total_entries: @account_tx_limit]})
      else
        paging_options
      end

    tx_hashes =
      list_tx_hash_by_transaction_query(condition)
      |> limit(@account_tx_limit)

    parse_result(tx_hashes, paging_options)
  end

  def account_transactions_data(paging_options) do
    paging_options =
      if Chain.transaction_estimated_count() > @tx_limit do
        Map.merge(paging_options, %{options: [total_entries: @tx_limit]})
      else
        paging_options
      end

    tx_hashes =
      list_tx_hash_by_transaction_query(true)
      |> limit(@tx_limit)

    parse_result(tx_hashes, paging_options)
  end

  defp parse_result(tx_hashes, paging_options) do
    if is_nil(paging_options) do
      results =
        tx_hashes
        |> limit(@export_limit)
        |> Repo.all()
        |> list_transaction_by_tx_hash()
        |> order_by([t], desc: t.block_number, desc: t.index)
        |> Repo.all()

      Enum.map(results, fn record ->
        stringify_and_unix_maps(record)
        |> Map.merge(%{
          method: Polyjuice.get_method_name(record.to_account_id, to_string(record.input))
        })
        |> Map.drop([:input, :to_account_id])
      end)
    else
      tx_hashes_struct =
        Repo.paginate(tx_hashes,
          page: paging_options[:page],
          page_size: paging_options[:page_size],
          options: paging_options[:options] || []
        )

      results =
        list_transaction_by_tx_hash(tx_hashes_struct.entries)
        |> order_by([t], desc: t.block_number, desc: t.index)
        |> Repo.all()

      parsed_result =
        Enum.map(results, fn record ->
          stringify_and_unix_maps(record)
          |> Map.merge(%{
            method: Polyjuice.get_method_name(record.to_account_id, to_string(record.input))
          })
          |> Map.drop([:input, :to_account_id])
        end)

      %{
        page: paging_options[:page],
        total_count: tx_hashes_struct.total_entries,
        txs: parsed_result
      }
    end
  end

  def list_tx_hash_by_transaction_query(condition) do
    from(t in Transaction,
      select:
        fragment("CASE WHEN ? IS NOT NULL THEN ? ELSE ? END", t.eth_hash, t.eth_hash, t.hash),
      where: ^condition,
      order_by: [desc: t.inserted_at, desc: t.block_number, desc: t.index]
    )
  end

  def list_home_transaction_by_tx_hash(hashes) do
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
      where: t.eth_hash in ^hashes or t.hash in ^hashes,
      select: %{
        hash:
          fragment(
            "'0x' || CASE WHEN ? IS NOT NULL THEN encode(?, 'hex') ELSE encode(?, 'hex') END",
            t.eth_hash,
            t.eth_hash,
            t.hash
          ),
        block_number: b.number,
        timestamp: b.timestamp,
        from: a2.eth_address,
        to:
          fragment(
            "'0x' || CASE WHEN ? IS NOT NULL THEN encode(?, 'hex') ELSE encode(?, 'hex') END",
            a3.eth_address,
            a3.eth_address,
            a3.script_hash
          ),
        to_alias:
          fragment(
            "
          CASE WHEN ? = 'eth_user' THEN '0x' || encode(?, 'hex')
          WHEN ? = 'udt' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE '0x' || encode(?, 'hex') END)
          WHEN ? = 'polyjuice_contract' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE '0x' || encode(?, 'hex') END)
          WHEN ? = 'polyjuice_creator' THEN 'Deploy Contract'
          ELSE '0x' ||encode(?, 'hex') END",
            a3.type,
            a3.eth_address,
            a3.type,
            s4.name,
            s4.name,
            a3.script_hash,
            a3.type,
            s4.name,
            s4.name,
            a3.eth_address,
            a3.type,
            a3.script_hash
          ),
        timestamp: b.timestamp,
        index: p.transaction_index,
        type: t.type
      }
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
      where: t.eth_hash in ^hashes or t.hash in ^hashes,
      select: %{
        hash:
          fragment(
            "'0x' || CASE WHEN ? IS NOT NULL THEN encode(?, 'hex') ELSE encode(?, 'hex') END",
            t.eth_hash,
            t.eth_hash,
            t.hash
          ),
        block_hash: b.hash,
        block_number: b.number,
        timestamp: b.timestamp,
        l1_block_number: b.layer1_block_number,
        from: a2.eth_address,
        to:
          fragment(
            "'0x' || CASE WHEN ? IS NOT NULL THEN encode(?, 'hex') ELSE encode(?, 'hex') END",
            a3.eth_address,
            a3.eth_address,
            a3.script_hash
          ),
        to_alias:
          fragment(
            "
          CASE WHEN ? = 'eth_user' THEN '0x' || encode(?, 'hex')
          WHEN ? = 'udt' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE '0x' || encode(?, 'hex') END)
          WHEN ? = 'polyjuice_contract' THEN (CASE WHEN ? IS NOT NULL THEN ? ELSE '0x' || encode(?, 'hex') END)
          WHEN ? = 'polyjuice_creator' THEN 'Deploy Contract'
          ELSE '0x' ||encode(?, 'hex') END",
            a3.type,
            a3.eth_address,
            a3.type,
            s4.name,
            s4.name,
            a3.script_hash,
            a3.type,
            s4.name,
            s4.name,
            a3.eth_address,
            a3.type,
            a3.script_hash
          ),
        status: b.status,
        timestamp: b.timestamp,
        index: p.transaction_index,
        polyjuice_status: p.status,
        type: t.type,
        nonce: t.nonce,
        fee: p.gas_price * p.gas_used,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        value: p.value,
        transaction_index: p.transaction_index,
        input: p.input,
        to_account_id: t.to_account_id,
        created_contract_address_hash: p.created_contract_address_hash
      }
    )
  end
end
