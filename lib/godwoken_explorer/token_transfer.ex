defmodule GodwokenExplorer.TokenTransfer do
  use GodwokenExplorer, :schema

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
end
