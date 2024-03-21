defmodule GodwokenExplorer.TokenTransfer do
  @moduledoc """
  Token's transfer record by contract.

  Use `GodwokenIndexer.Transform.TokenTransfers` to parse from log.
  """
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [utc_to_unix: 1, balance_to_view: 2]

  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.{Account, Address}

  @constant "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  @wckb_deposit_signature "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c"
  @wckb_withdrawal_signature "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"
  @erc1155_single_transfer_signature "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
  @erc1155_batch_transfer_signature "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"

  @transfer_function_signature "0xa9059cbb"
  @account_transfer_limit 100_000
  @export_limit 5_000

  @typedoc """
     * `amount` - Transfer amount.
     * `log_index` - Transaction's log index.
     * `token_id` - The erc721's token_id.
     * `from_address_hash` - Transfer sender.
     * `to_address_hash` - Transfer receiver.
     * `token_contract_address_hash` - Which token contract.
     * `amounts` - Erc1155.
     * `token_ids` - Erc1155.
     * `block_number` - Layer2 block.
     * `block_hash` - Layer2 block.
     * `transaction_hash` - Layer2 transaction.
  """

  @type t :: %__MODULE__{
          amount: Decimal.t(),
          log_index: non_neg_integer(),
          token_id: non_neg_integer() | nil,
          from_address_hash: Hash.Address.t(),
          to_address_hash: Hash.Address.t(),
          token_contract_address_hash: Hash.Address.t(),
          amounts: list(Decimal.t()),
          token_ids: list(Decimal.t()),
          block_number: non_neg_integer(),
          block_hash: Hash.Full.t(),
          block: %Ecto.Association.NotLoaded{} | Block.t(),
          transaction_hash: Hash.Full.t(),
          transaction: %Ecto.Association.NotLoaded{} | Transaction.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "token_transfers" do
    field(:amount, :decimal)
    field(:block_number, :integer)
    field(:log_index, :integer, primary_key: true)
    field(:token_id, :decimal)
    field(:amounts, {:array, :decimal})
    field(:token_ids, {:array, :decimal})

    belongs_to(:from_account, Account,
      foreign_key: :from_address_hash,
      references: :eth_address,
      type: Hash.Address
    )

    belongs_to(:to_account, Account,
      foreign_key: :to_address_hash,
      references: :eth_address,
      type: Hash.Address
    )

    belongs_to(:receiver_address, Address,
      foreign_key: :to_address_hash,
      references: :eth_address,
      type: Hash.Address,
      define_field: false
    )

    belongs_to(:udt, UDT,
      foreign_key: :token_contract_address_hash,
      references: :contract_address_hash,
      type: Hash.Address
    )

    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, type: Hash.Full)

    belongs_to(:transaction, Transaction,
      foreign_key: :transaction_hash,
      primary_key: true,
      references: :eth_hash,
      type: Hash.Full
    )

    timestamps()
  end

  @required_attrs ~w(block_number log_index from_address_hash to_address_hash token_contract_address_hash transaction_hash block_hash)a
  @optional_attrs ~w(amount token_id amounts token_ids)a

  @doc false
  def changeset(%TokenTransfer{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  @doc """
  Value that represents a token transfer in a `t:Explorer.Chain.Log.t/0`'s
  `first_topic` field.
  """
  def constant, do: @constant
  def wckb_deposit_signature, do: @wckb_deposit_signature
  def wckb_withdrawal_signature, do: @wckb_withdrawal_signature
  def erc1155_single_transfer_signature, do: @erc1155_single_transfer_signature
  def erc1155_batch_transfer_signature, do: @erc1155_batch_transfer_signature

  @doc """
  ERC 20's transfer(address,uint256) function signature
  """
  def transfer_function_signature, do: @transfer_function_signature

  def list(%{eth_address: eth_address, udt_address: udt_address}, paging_options) do
    condition =
      dynamic(
        [tt],
        tt.token_contract_address_hash == ^udt_address and
          (tt.from_address_hash == ^eth_address or tt.to_address_hash == ^eth_address)
      )

    paginate_result = base_query_by(condition, paging_options)
    parse_json_result(paginate_result, init_query())
  end

  def list(%{eth_address: eth_address}, paging_options) do
    token_transfer_count =
      case Repo.get_by(Account, eth_address: eth_address) do
        %Account{token_transfer_count: token_transfer_count} -> token_transfer_count || 0
        nil -> Chain.address_to_token_transfer_count(eth_address)
      end

    from_condition =
      dynamic(
        [tt],
        tt.from_address_hash == ^eth_address
      )

    to_condition =
      dynamic(
        [tt],
        tt.to_address_hash == ^eth_address
      )

    paging_options =
      if token_transfer_count > @account_transfer_limit do
        paging_options |> Map.merge(%{options: [total_entries: @account_transfer_limit]})
      else
        paging_options
      end

    from_query =
      from(tt in TokenTransfer,
        join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        where: ^from_condition,
        where: u.eth_type == :erc20,
        select: %{
          transaction_hash: tt.transaction_hash,
          log_index: tt.log_index,
          block_number: tt.block_number
        }
      )

    to_query =
      from(tt in TokenTransfer,
        join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        where: ^to_condition,
        where: u.eth_type == :erc20,
        select: %{
          transaction_hash: tt.transaction_hash,
          log_index: tt.log_index,
          block_number: tt.block_number
        }
      )

    if is_nil(paging_options) do
      results =
        from(q in subquery(union_all(from_query, ^to_query)),
          join: t in Transaction,
          on: t.eth_hash == q.transaction_hash
        )
        |> order_by([tt, t], desc: tt.block_number, desc: t.index, desc: tt.log_index)
        |> limit(@export_limit)
        |> Repo.all()

      if results == [] do
        []
      else
        query =
          Enum.reduce(results, init_query(), fn %{
                                                  transaction_hash: transaction_hash,
                                                  log_index: log_index
                                                },
                                                query_acc ->
            query_acc
            |> or_where(
              [tt],
              tt.transaction_hash == ^transaction_hash and tt.log_index == ^log_index
            )
          end)

        query
        |> order_by([tt], desc: tt.block_number, desc: tt.log_index)
        |> Repo.all()
        |> Enum.map(fn transfer ->
          transfer
          |> Map.put(:timestamp, utc_to_unix(transfer[:timestamp]))
          |> Map.merge(%{
            hash: to_string(transfer[:hash]),
            transfer_value:
              balance_to_view(transfer[:transfer_value], transfer[:udt_decimal] || 0)
          })
        end)
      end
    else
      paginate_result =
        from(q in subquery(union_all(from_query, ^to_query)))
        |> order_by([tt], desc: tt.block_number, desc: tt.log_index)
        |> Repo.paginate(
          page: paging_options[:page],
          page_size: paging_options[:page_size],
          options: paging_options[:options] || []
        )

      parse_json_result(paginate_result, init_query())
    end
  end

  def list(%{udt_address: udt_address}, paging_options) do
    condition =
      dynamic(
        [tt],
        tt.token_contract_address_hash == ^udt_address
      )

    if is_nil(paging_options) do
      export_result(condition, init_query())
    else
      token_transfer_count =
        case Repo.get_by(Account, eth_address: udt_address) do
          %Account{token_transfer_count: token_transfer_count} -> token_transfer_count || 0
          nil -> Chain.address_to_token_transfer_count(udt_address)
        end

      paging_options =
        if token_transfer_count > @account_transfer_limit do
          paging_options |> Map.merge(%{options: [total_entries: @account_transfer_limit]})
        else
          paging_options
        end

      paginate_result = base_query_by(condition, paging_options)

      parse_json_result(paginate_result, init_query())
    end
  end

  def list(%{tx_hash: tx_hash}, paging_options) do
    condition =
      dynamic(
        [tt],
        tt.transaction_hash == ^tx_hash
      )

    if is_nil(paging_options) do
      export_result(condition, init_query())
    else
      paginate_result = base_query_by(condition, paging_options)

      parse_json_result(paginate_result, init_query())
    end
  end

  defp init_query do
    from(tt in TokenTransfer,
      left_join: a1 in Account,
      on: a1.eth_address == tt.from_address_hash,
      left_join: a2 in Account,
      on: a2.eth_address == tt.to_address_hash,
      join: b in Block,
      on: b.hash == tt.block_hash,
      left_join: u in UDT,
      on: u.contract_address_hash == tt.token_contract_address_hash,
      join: t in Transaction,
      on: t.eth_hash == tt.transaction_hash,
      join: p in Polyjuice,
      on: p.tx_hash == t.hash,
      select: %{
        hash: tt.transaction_hash,
        block_number: tt.block_number,
        timestamp: b.timestamp,
        from:
          fragment(
            "'0x' || CASE WHEN ? IS NULL THEN encode(?, 'hex')
      WHEN ? in ('eth_user', 'polyjuice_contract') THEN encode(?, 'hex')
    ELSE encode(?, 'hex') END",
            a1,
            tt.from_address_hash,
            a1.type,
            a1.eth_address,
            a1.script_hash
          ),
        to:
          fragment(
            "'0x' || CASE WHEN ? IS NULL THEN encode(?, 'hex')
      WHEN ? in ('eth_user', 'polyjuice_contract') THEN encode(?, 'hex')
    ELSE encode(?, 'hex') END",
            a2,
            tt.to_address_hash,
            a2.type,
            a2.eth_address,
            a2.script_hash
          ),
        udt_id: u.id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        transfer_value: tt.amount,
        udt_decimal: u.decimal,
        status: b.status,
        polyjuice_status: p.status,
        gas_limit: p.gas_limit,
        gas_price: p.gas_price,
        gas_used: p.gas_used,
        transfer_count: tt.amount,
        nonce: t.nonce,
        log_index: tt.log_index
      }
    )
  end

  def export_result(condition, init_query) do
    results =
      from(tt in TokenTransfer,
        join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        join: t in Transaction,
        on: t.eth_hash == tt.transaction_hash,
        where: ^condition,
        select: %{
          transaction_hash: tt.transaction_hash,
          log_index: tt.log_index
        },
        order_by: [desc: tt.block_number, desc: t.index, desc: tt.log_index]
      )
      |> limit(@export_limit)
      |> Repo.all()

    if results == [] do
      []
    else
      query =
        Enum.reduce(results, init_query, fn %{
                                              transaction_hash: transaction_hash,
                                              log_index: log_index
                                            },
                                            query_acc ->
          query_acc
          |> or_where(
            [tt],
            tt.transaction_hash == ^transaction_hash and tt.log_index == ^log_index
          )
        end)

      query
      |> order_by([tt, a1, a2, b, u, t],
        desc: tt.block_number,
        desc: t.index,
        desc: tt.log_index
      )
      |> Repo.all()
      |> Enum.map(fn transfer ->
        transfer
        |> Map.put(:timestamp, utc_to_unix(transfer[:timestamp]))
        |> Map.merge(%{
          hash: to_string(transfer[:hash]),
          transfer_value: balance_to_view(transfer[:transfer_value], transfer[:udt_decimal] || 0)
        })
      end)
    end
  end

  def snapshot_erc721_token(token_contract_address_hash, start_block_number, end_block_number) do
    from(tt in TokenTransfer,
      where:
        tt.token_contract_address_hash == ^token_contract_address_hash and
          tt.block_number >= ^start_block_number and tt.block_number <= ^end_block_number,
      select: %{
        address_hash: fragment("'0x' || encode(?, 'hex')", tt.to_address_hash),
        token_id: tt.token_id
      },
      distinct: tt.token_id,
      order_by: [desc: tt.block_number]
    )
    |> Repo.all()
  end

  defp parse_json_result(paginate_result, init_query) do
    if paginate_result.total_entries != 0 do
      query =
        Enum.reduce(paginate_result.entries, init_query, fn %{
                                                              transaction_hash: transaction_hash,
                                                              log_index: log_index
                                                            },
                                                            query_acc ->
          query_acc
          |> or_where(
            [tt],
            tt.transaction_hash == ^transaction_hash and tt.log_index == ^log_index
          )
        end)

      parsed_results =
        query
        |> order_by([tt, a1, a2, b, u, t],
          desc: tt.block_number,
          desc: t.index,
          desc: tt.log_index
        )
        |> Repo.all()
        |> Enum.map(fn transfer ->
          transfer
          |> Map.put(:timestamp, utc_to_unix(transfer[:timestamp]))
          |> Map.merge(%{
            hash: to_string(transfer[:hash]),
            transfer_value:
              balance_to_view(transfer[:transfer_value], transfer[:udt_decimal] || 0)
          })
        end)

      %{
        page: paginate_result.page_number,
        total_count: paginate_result.total_entries,
        txs: parsed_results
      }
    else
      %{
        page: paginate_result.page_number,
        total_count: paginate_result.total_entries,
        txs: []
      }
    end
  end

  defp base_query_by(condition, paging_options) do
    from(tt in TokenTransfer,
      join: u in UDT,
      on: u.contract_address_hash == tt.token_contract_address_hash,
      join: t in Transaction,
      on: t.eth_hash == tt.transaction_hash,
      where: ^condition,
      where: u.eth_type == :erc20,
      select: %{
        transaction_hash: tt.transaction_hash,
        log_index: tt.log_index
      },
      order_by: [desc: tt.block_number, desc: t.index, desc: tt.log_index]
    )
    |> Repo.paginate(
      page: paging_options[:page],
      page_size: paging_options[:page_size],
      options: paging_options[:options] || []
    )
  end
end
