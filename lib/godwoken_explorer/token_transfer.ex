defmodule GodwokenExplorer.TokenTransfer do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [utc_to_unix: 1]

  alias GodwokenExplorer.Chain

  @constant "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  @erc1155_single_transfer_signature "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
  @erc1155_batch_transfer_signature "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"

  @transfer_function_signature "0xa9059cbb"

  @account_transfer_limit 100_000

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "token_transfers" do
    field(:transaction_hash, :binary, primary_key: true)
    field(:amount, :decimal)
    field(:block_number, :integer)
    field(:block_hash, :binary)
    field(:log_index, :integer, primary_key: true)
    field(:token_id, :decimal)
    field(:from_address_hash, :binary)
    field(:to_address_hash, :binary)
    field(:token_contract_address_hash, :binary)

    timestamps()
  end

  @required_attrs ~w(block_number log_index from_address_hash to_address_hash token_contract_address_hash transaction_hash block_hash)a
  @optional_attrs ~w(amount token_id)a

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

    udt = UDT.get_by_contract_address(udt_address)
    udt_id = Integer.to_string(udt.id)

    init_query =
      from(tt in TokenTransfer,
        left_join: a1 in Account,
        on: a1.short_address == tt.from_address_hash,
        join: a2 in Account,
        on: a2.short_address == tt.to_address_hash,
        join: b in Block,
        on: b.hash == tt.block_hash,
        join: p in Polyjuice,
        on: p.tx_hash == tt.transaction_hash,
        join: t in Transaction,
        on: t.hash == tt.transaction_hash,
        select: %{
          hash: tt.transaction_hash,
          block_number: tt.block_number,
          inserted_at: b.inserted_at,
          from:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a1,
              tt.from_address_hash,
              a1.type,
              a1.eth_address,
              a1.short_address
            ),
          to:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a2,
              tt.to_address_hash,
              a2.type,
              a2.eth_address,
              a2.short_address
            ),
          udt_id: ^udt_id,
          udt_name: ^udt.name,
          udt_symbol: ^udt.symbol,
          transfer_value: fragment("
        ? / power(10, ?)::decimal
        ", tt.amount, ^udt.decimal),
          status: b.status,
          polyjuice_status: p.status,
          gas_limit: p.gas_limit,
          gas_price: p.gas_price,
          gas_used: p.gas_used,
          transfer_count: tt.amount,
          nonce: t.nonce
        }
      )

    parse_json_result(paginate_result, init_query)
  end

  def list(%{eth_address: eth_address}, paging_options) do
    token_transfer_count =
      case Account.search(eth_address) do
        %Account{token_transfer_count: token_transfer_count} -> token_transfer_count || 0
        nil -> Chain.address_to_token_transfer_count(eth_address)
      end

    from_condition =
      if token_transfer_count > @account_transfer_limit do
        datetime = Timex.now() |> Timex.shift(days: -5)

        dynamic(
          [tt],
          tt.from_address_hash == ^eth_address and tt.inserted_at > ^datetime
        )
      else
        dynamic(
          [tt],
          tt.from_address_hash == ^eth_address
        )
      end

    to_condition =
      if token_transfer_count > @account_transfer_limit do
        datetime = Timex.now() |> Timex.shift(days: -5)

        dynamic(
          [tt],
          tt.to_address_hash == ^eth_address and tt.inserted_at > ^datetime
        )
      else
        dynamic(
          [tt],
          tt.to_address_hash == ^eth_address
        )
      end

    from_query =
      from(tt in TokenTransfer,
        where: ^from_condition,
        select: %{
          transaction_hash: tt.transaction_hash,
          log_index: tt.log_index,
          block_number: tt.block_number,
          inserted_at: tt.inserted_at
        }
      )

    to_query =
      from(tt in TokenTransfer,
        where: ^to_condition,
        select: %{
          transaction_hash: tt.transaction_hash,
          log_index: tt.log_index,
          block_number: tt.block_number,
          inserted_at: tt.inserted_at
        }
      )

    paginate_result =
      from(q in subquery(union_all(from_query, ^to_query)))
      |> order_by([tt], desc: tt.block_number, desc: tt.inserted_at)
      |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])

    init_query =
      from(tt in TokenTransfer,
        left_join: a1 in Account,
        on: a1.short_address == tt.from_address_hash,
        left_join: a2 in Account,
        on: a2.short_address == tt.to_address_hash,
        join: b in Block,
        on: b.hash == tt.block_hash,
        join: a4 in Account,
        on: a4.short_address == tt.token_contract_address_hash,
        left_join: u5 in UDT,
        on: u5.bridge_account_id == a4.id,
        join: p in Polyjuice,
        on: p.tx_hash == tt.transaction_hash,
        join: t in Transaction,
        on: t.hash == tt.transaction_hash,
        select: %{
          hash: tt.transaction_hash,
          block_number: tt.block_number,
          inserted_at: b.inserted_at,
          from:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a1,
              tt.from_address_hash,
              a1.type,
              a1.eth_address,
              a1.short_address
            ),
          to:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a2,
              tt.to_address_hash,
              a2.type,
              a2.eth_address,
              a2.short_address
            ),
          udt_id: u5.id,
          udt_name: u5.name,
          udt_symbol: u5.symbol,
          transfer_value:
            fragment(
              "CASE WHEN ? IS NOT NULL THEN ? / power(10, ?)::decimal
            ELSE ? END",
              u5.decimal,
              tt.amount,
              u5.decimal,
              tt.amount
            ),
          status: b.status,
          polyjuice_status: p.status,
          gas_limit: p.gas_limit,
          gas_price: p.gas_price,
          gas_used: p.gas_used,
          transfer_count: tt.amount,
          nonce: t.nonce
        }
      )

    parse_json_result(paginate_result, init_query)
  end

  def list(%{udt_address: udt_address}, paging_options) do
    datetime = Timex.now() |> Timex.shift(days: -5)

    condition =
      dynamic(
        [tt],
        tt.token_contract_address_hash == ^udt_address and tt.inserted_at > ^datetime
      )

    paginate_result = base_query_by(condition, paging_options)

    udt = UDT.get_by_contract_address(udt_address)
    udt_id = Integer.to_string(udt.id)

    init_query =
      from(tt in TokenTransfer,
        left_join: a1 in Account,
        on: a1.short_address == tt.from_address_hash,
        left_join: a2 in Account,
        on: a2.short_address == tt.to_address_hash,
        join: b in Block,
        on: b.hash == tt.block_hash,
        join: p in Polyjuice,
        on: p.tx_hash == tt.transaction_hash,
        join: t in Transaction,
        on: t.hash == tt.transaction_hash,
        select: %{
          hash: tt.transaction_hash,
          block_number: tt.block_number,
          inserted_at: b.inserted_at,
          from:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a1,
              tt.from_address_hash,
              a1.type,
              a1.eth_address,
              a1.short_address
            ),
          to:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a2,
              tt.to_address_hash,
              a2.type,
              a2.eth_address,
              a2.short_address
            ),
          udt_id: ^udt_id,
          udt_name: ^udt.name,
          udt_symbol: ^udt.symbol,
          transfer_value: fragment("
        ? / power(10, ?)::decimal
        ", tt.amount, ^udt.decimal),
          status: b.status,
          polyjuice_status: p.status,
          gas_limit: p.gas_limit,
          gas_price: p.gas_price,
          gas_used: p.gas_used,
          transfer_count: tt.amount,
          nonce: t.nonce
        }
      )

    parse_json_result(paginate_result, init_query)
  end

  def list(%{tx_hash: tx_hash}, paging_options) do
    condition =
      dynamic(
        [tt],
        tt.transaction_hash == ^tx_hash
      )

    paginate_result = base_query_by(condition, paging_options)

    init_query =
      from(tt in TokenTransfer,
        left_join: a1 in Account,
        on: a1.short_address == tt.from_address_hash,
        left_join: a2 in Account,
        on: a2.short_address == tt.to_address_hash,
        join: b in Block,
        on: b.hash == tt.block_hash,
        join: a4 in Account,
        on: a4.short_address == tt.token_contract_address_hash,
        left_join: u5 in UDT,
        on: u5.bridge_account_id == a4.id,
        join: p in Polyjuice,
        on: p.tx_hash == tt.transaction_hash,
        select: %{
          hash: tt.transaction_hash,
          block_number: tt.block_number,
          inserted_at: b.inserted_at,
          from:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a1,
              tt.from_address_hash,
              a1.type,
              a1.eth_address,
              a1.short_address
            ),
          to:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'escape')
          WHEN ? in ('user', 'polyjuice_contract') THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END",
              a2,
              tt.to_address_hash,
              a2.type,
              a2.eth_address,
              a2.short_address
            ),
          udt_id: u5.id,
          udt_name: u5.name,
          udt_symbol: u5.symbol,
          transfer_value:
            fragment(
              "CASE WHEN ? IS NULL THEN ? ELSE ? / power(10, ?)::decimal END",
              u5,
              tt.amount,
              tt.amount,
              u5.decimal
            ),
          status: b.status,
          polyjuice_status: p.status
        }
      )

    parse_json_result(paginate_result, init_query)
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
        |> order_by([tt], desc: tt.block_number, desc: tt.inserted_at, desc: tt.log_index)
        |> Repo.all()
        |> Enum.map(fn transfer ->
          transfer
          |> Map.put(:timestamp, utc_to_unix(transfer[:inserted_at]))
          |> Map.delete(:inserted_at)
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
      where: ^condition,
      select: %{
        transaction_hash: tt.transaction_hash,
        log_index: tt.log_index
      },
      order_by: [desc: tt.block_number, desc: tt.inserted_at]
    )
    |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])
  end
end
