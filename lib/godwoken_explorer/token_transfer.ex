defmodule GodwokenExplorer.TokenTransfer do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [utc_to_unix: 1]

  @constant "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  @erc1155_single_transfer_signature "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
  @erc1155_batch_transfer_signature "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"

  @transfer_function_signature "0xa9059cbb"

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
    udt = UDT.get_by_contract_address(udt_address)

    from(tt in TokenTransfer,
      join: a1 in Account,
      on: a1.short_address == tt.from_address_hash,
      join: a2 in Account,
      on: a2.short_address == tt.to_address_hash,
      join: b in Block,
      on: b.hash == tt.block_hash,
      join: p in Polyjuice,
      on: p.tx_hash == tt.transaction_hash,
      where:
        tt.token_contract_address_hash == ^udt_address and
          (tt.from_address_hash == ^eth_address or tt.to_address_hash == ^eth_address),
      select: %{
        hash: tt.transaction_hash,
        block_number: tt.block_number,
        inserted_at: b.inserted_at,
        from: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a1.type, a1.eth_address, a1.short_address),
        to: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a2.type, a2.eth_address, a2.short_address),
        udt_id: ^udt.id,
        udt_name: ^udt.name,
        udt_symbol: ^udt.symbol,
        transfer_value: fragment("
        ? / power(10, ?)::decimal
        ", tt.amount, ^udt.decimal),
        status: b.status,
        polyjuice_status: p.status
      },
      order_by: [desc: tt.block_number]
    )
    |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])
    |> parse_json_result()
  end

  def list(%{eth_address: eth_address}, paging_options) do
    from(tt in TokenTransfer,
      join: a1 in Account,
      on: a1.short_address == tt.from_address_hash,
      join: a2 in Account,
      on: a2.short_address == tt.to_address_hash,
      join: b in Block,
      on: b.hash == tt.block_hash,
      join: a4 in Account,
      on: a4.short_address == tt.token_contract_address_hash,
      left_join: u5 in UDT,
      on: u5.id == a4.id,
      left_join: u6 in UDT,
      on: u6.bridge_account_id == a4.id,
      join: p in Polyjuice,
      on: p.tx_hash == tt.transaction_hash,
      where: tt.from_address_hash == ^eth_address or tt.to_address_hash == ^eth_address,
      select: %{
        hash: tt.transaction_hash,
        block_number: tt.block_number,
        inserted_at: b.inserted_at,
        from: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a1.type, a1.eth_address, a1.short_address),
        to: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a2.type, a2.eth_address, a2.short_address),
        udt_id: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u5, u6.id, u5.id),
        udt_name: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u5, u6.name, u5.name),
        udt_symbol: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u5, u6.symbol, u5.symbol),
        transfer_value:
          fragment(
            "CASE WHEN ? IS NOT NULL THEN ? / power(10, ?)::decimal
            WHEN ? IS NOT NULL THEN ? / power(10, ?)::decimal
            ELSE ? END",
            u5,
            tt.amount,
            u5.decimal,
            u6,
            tt.amount,
            u6.decimal,
            tt.amount
          ),
          status: b.status,
          polyjuice_status: p.status
      },
      order_by: [desc: tt.block_number]
    )
    |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])
    |> parse_json_result()
  end

  def list(%{udt_address: udt_address}, paging_options) do
    udt = UDT.get_by_contract_address(udt_address)

    from(tt in TokenTransfer,
      join: a1 in Account,
      on: a1.short_address == tt.from_address_hash,
      join: a2 in Account,
      on: a2.short_address == tt.to_address_hash,
      join: b in Block,
      on: b.hash == tt.block_hash,
      join: p in Polyjuice,
      on: p.tx_hash == tt.transaction_hash,
      where: tt.token_contract_address_hash == ^udt_address,
      select: %{
        hash: tt.transaction_hash,
        block_number: tt.block_number,
        inserted_at: b.inserted_at,
        from: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a1.type, a1.eth_address, a1.short_address),
        to: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a2.type, a2.eth_address, a2.short_address),
        udt_id: ^udt.id,
        udt_name: ^udt.name,
        udt_symbol: ^udt.symbol,
        transfer_value: fragment("
        ? / power(10, ?)::decimal
        ", tt.amount, ^udt.decimal),
        status: b.status,
        polyjuice_status: p.status
      },
      order_by: [desc: tt.block_number]
    )
    |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])
    |> parse_json_result()
  end

  defp parse_json_result(results) do
    parsed_results =
      results.entries
      |> Enum.map(fn transfer ->
        transfer
        |> Map.put(:timestamp, utc_to_unix(transfer[:inserted_at]))
        |> Map.delete(:inserted_at)
      end)

    %{
      page: results.page_number,
      total_count: results.total_entries,
      txs: parsed_results
    }
  end
end
