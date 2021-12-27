defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2, stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Chain.Cache.Transactions

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :status, Ecto.Enum, values: [:committed, :finalized], default: :committed
    field :to_account_id, :integer
    field :type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice]
    field :block_number, :integer
    field :block_hash, :binary

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
      |> Repo.insert([on_conflict: :nothing])

    UDTTransfer.create_udt_transfer(attrs)
    transaction
  end

  def create_transaction(%{type: :polyjuice_creator} = attrs) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
      |> Repo.insert([on_conflict: :nothing])

    PolyjuiceCreator.create_polyjuice_creator(attrs)
    transaction
  end

  def create_transaction(%{type: :polyjuice} = attrs) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Repo.insert([on_conflict: :nothing])

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
          |> Map.take([:hash, :from, :to, :type])
          |> Map.merge(%{timestamp: t.block.inserted_at})
        end)

      _ ->
        from(t in Transaction,
          join: b in Block,
          on: b.hash == t.block_hash,
          join: a2 in Account,
          on: a2.id == t.from_account_id,
          join: a3 in Account,
          on: a3.id == t.to_account_id,
          select: %{
            hash: t.hash,
            timestamp: b.inserted_at,
            from: a2.eth_address,
            to: fragment("
              CASE WHEN a3.type = 'user' THEN encode(a3.eth_address, 'escape')
                 WHEN a3.type = 'polyjuice_contract' THEN encode(a3.short_address, 'escape')
                 ELSE a3.id::text END"),
            type: t.type
          },
          order_by: [desc: t.block_number, desc: t.inserted_at],
          limit: 10
        )
        |> Repo.all()
    end
  end

  def find_by_hash(hash) do
    tx =
      from(t in Transaction,
        join: b in Block,
        on: b.hash == t.block_hash,
        join: a2 in Account,
        on: a2.id == t.from_account_id,
        join: a3 in Account,
        on: a3.id == t.to_account_id,
        where: t.hash == ^hash,
        select: %{
          hash: t.hash,
          l2_block_number: t.block_number,
          timestamp: b.timestamp,
          l1_block_number: b.layer1_block_number,
          from: a2.eth_address,
          to: fragment("
              CASE WHEN a3.type = 'user' THEN encode(a3.eth_address, 'escape')
                 WHEN a3.type = 'polyjuice_contract' THEN encode(a3.short_address, 'escape')
                 ELSE a3.id::text END"),
          type: t.type,
          status: t.status,
          nonce: t.nonce,
          args: t.args
        }
      )
      |> Repo.one()

    if is_nil(tx) do
      %{}
    else
      if tx.type == :polyjuice do
        with %Polyjuice{} = p <- Repo.get_by(Polyjuice, tx_hash: tx.hash) do
          tx
          |> Map.merge(%{
            gas_price: p.gas_price,
            gas_used: p.gas_used,
            gas_limit: p.gas_limit,
            receive_eth_address: p.receive_eth_address,
            transfer_count: p.transfer_count,
            value: p.value,
            input: p.input
          })
        end
      else
        tx
      end
    end
  end

  def list_by_account(%{
        type: type,
        account_id: account_id,
        eth_address: eth_address,
        contract_id: contract_id
      })
      when type == :user do
    query_a = list_by_account_transaction_query(dynamic([t], t.from_account_id == ^account_id and t.to_account_id == ^contract_id))
    query_b = list_by_account_polyjuice_query(eth_address)

    from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])
  end

  def list_by_account(%{type: type, account_id: account_id, eth_address: eth_address})
      when type == :user do
    query_a = list_by_account_transaction_query(dynamic([t], t.from_account_id == ^account_id))
    query_b = list_by_account_polyjuice_query(eth_address)

    from(q in subquery(query_a |> union(^query_b)), order_by: [desc: q.inserted_at])
  end

  def list_by_account(%{type: type, account_id: account_id, eth_address: _eth_address})
      when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] do
    displayed = Account.display_id(account_id)
    from(t in Transaction,
      join: b in Block,
      on: [hash: t.block_hash],
      join: a2 in Account,
      on: a2.id == t.from_account_id,
      left_join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      where: t.to_account_id == ^account_id,
      select: %{
        hash: t.hash,
        block_number: b.number,
        timestamp: b.timestamp,
        from: a2.eth_address,
        to: ^displayed,
        type: t.type,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        receive_eth_address: p.receive_eth_address,
        transfer_count: p.transfer_count,
        value: p.value,
        input: p.input
      },
      order_by: [desc: t.inserted_at]
    )
  end
  def list_by_account(%{account_id: account_id, tx_type: tx_type})
      when tx_type == "transfer" do
    from(t in Transaction,
      join: b in Block,
      on: [hash: t.block_hash],
      join: a2 in Account,
      on: a2.id == t.from_account_id,
      join: a3 in Account,
      on: a3.id == t.to_account_id,
      join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      where: t.to_account_id == ^account_id and not(is_nil(p.transfer_count)),
      select: %{
        hash: t.hash,
        block_number: b.number,
        timestamp: b.timestamp,
        from: a2.eth_address,
        to: fragment("
              CASE WHEN a3.type = 'user' THEN encode(a3.eth_address, 'escape')
                 WHEN a3.type = 'polyjuice_contract' THEN encode(a3.short_address, 'escape')
                 ELSE a3.id::text END"),
        type: t.type,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        receive_eth_address: p.receive_eth_address,
        transfer_count: p.transfer_count,
        value: p.value,
        input: p.input
      },
      order_by: [desc: t.inserted_at]
    )
  end

  # TODO: maybe can refactor
  def count_of_account(%{
      type: type,
      account_id: account_id,
      eth_address: eth_address,
    })
      when type == :user do
    query_a =
      from(t in Transaction,
        where:
          t.from_account_id == ^account_id,
        select: t.hash
          )
    query_b =
      from(p in Polyjuice,
        where:
          p.receive_eth_address == ^eth_address,
        select: p.tx_hash
          )
    query_a |> union(^query_b) |> Repo.all() |> Enum.count()
  end
  def count_of_account(%{type: type, account_id: account_id, eth_address: _eth_address})
      when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] do
    from(t in Transaction,
      left_join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      where: t.to_account_id == ^account_id
      ) |> Repo.aggregate(:count)
  end

  def account_transactions_data(
        %{account_id: account_id, tx_type: tx_type},
        page
      ) do
    txs =
      list_by_account(%{
        account_id: account_id,
        tx_type: tx_type
      })

    original_struct = Repo.paginate(txs, page: page)

    decimal =
      case Repo.get(UDT,account_id) do
        %UDT{decimal: decimal} ->
          decimal
        _ ->
          8
      end

    parsed_result =
      Enum.map(original_struct.entries, fn record ->
        record
        |> Map.merge(%{transfer_count: balance_to_view(record.transfer_count, decimal)})
        |> stringify_and_unix_maps()
      end)

    %{
      page: Integer.to_string(original_struct.page_number),
      total_count: Integer.to_string(original_struct.total_entries),
      txs: parsed_result
    }
  end

  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: eth_address, contract_id: contract_id},
        page
      ) do
    txs =
      list_by_account(%{
        type: type,
        account_id: account_id,
        eth_address: eth_address,
        contract_id: contract_id
      })

    original_struct = Repo.paginate(txs, page: page)

    parsed_result =
      Enum.map(original_struct.entries, fn record ->
        stringify_and_unix_maps(record)
      end)

    %{
      page: Integer.to_string(original_struct.page_number),
      total_count: Integer.to_string(original_struct.total_entries),
      txs: parsed_result
    }
  end
  def account_transactions_data(
        %{type: type, account_id: account_id, eth_address: eth_address},
        page
      ) do
    txs = list_by_account(%{type: type, account_id: account_id, eth_address: eth_address})
    original_struct = Repo.paginate(txs, page: page)

    parsed_result =
      Enum.map(original_struct.entries, fn record ->
        stringify_and_unix_maps(record)
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
      join: sa2 in Account,
      on: sa2.id == t.from_account_id,
      join: sa3 in Account,
      on: sa3.id == t.to_account_id,
      left_join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      where: ^condition,
      select: %{
        hash: t.hash,
        block_number: b.number,
        timestamp: b.timestamp,
        from: sa2.eth_address,
        to: fragment("
              CASE WHEN sa3.type = 'user' THEN encode(sa3.eth_address, 'escape')
                 WHEN sa3.type = 'polyjuice_contract' THEN encode(sa3.short_address, 'escape')
                 ELSE sa3.id::text END"),
        type: t.type,
        nonce: t.nonce,
        args: t.args,
        inserted_at: t.inserted_at,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        gas_limit: p.gas_limit,
        value: p.value,
        receive_eth_address: p.receive_eth_address,
        transfer_count: p.transfer_count,
        input: p.input
      }
    )
  end

  defp list_by_account_polyjuice_query(eth_address) do
      from(p in Polyjuice,
        join: t in Transaction, on: t.hash == p.tx_hash,
        join: b in Block,
        on: b.hash == t.block_hash,
        join: a2 in Account,
        on: a2.id == t.from_account_id,
        join: a3 in Account,
        on: a3.id == t.to_account_id,
        where:
          p.receive_eth_address == ^eth_address,
        select: %{
          hash: p.tx_hash,
          block_number: b.number,
          timestamp: b.timestamp,
          from: a2.eth_address,
          to: fragment("
                CASE WHEN a3.type = 'user' THEN encode(a3.eth_address, 'escape')
                  WHEN a3.type = 'polyjuice_contract' THEN encode(a3.short_address, 'escape')
                  ELSE a3.id::text END"),
          type: t.type,
          nonce: t.nonce,
          args: t.args,
          insertetd_at: t.inserted_at,
          gas_price: p.gas_price,
          gas_used: p.gas_used,
          gas_limit: p.gas_limit,
          value: p.value,
          receive_eth_address: p.receive_eth_address,
          transfer_count: p.transfer_count,
          input: p.input
        })
  end
end
