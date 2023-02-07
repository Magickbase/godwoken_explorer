defmodule GodwokenExplorer.Polyjuice do
  @moduledoc """
  Parse Polyjuice args and belongs to Transaction.

  Polyjuice is an Ethereum EVM-compatible execution environment, which allows Solidity based smart contracts to run on Nervos.
  The goal of the project is 100% compatibility, allowing all Ethereum contracts to run on Nervos without any modification.
  Polyjuice args builder: https://github.com/godwokenrises/godwoken-polyjuice/blob/5f146f764067afb103f2ee9c7705e4a77e63beed/polyjuice-tests/src/helper.rs#L339
  """
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.SmartContract
  import Ecto.Changeset
  import Ecto.Query

  require Logger

  alias ABI.FunctionSelector
  alias GodwokenExplorer.Chain.{Data, Hash}

  @typedoc """
    * `is_create` - This transction deployed contract.
    * `gas_limit` - Gas limited value.
    * `gas_price` - How much the sender is willing to pay for `gas`
    * `gas_used` - the gas used for just `transaction`.  `nil` when transaction is pending or has only been collated into
     one of the `uncles` in one of the `forks`.
    * `value` - pCKB transferred from `from_address` to `to_address`
    * `input`- data sent along with the transaction
    * `input_size`- data size.
    * `transaction_index` - index of this transaction in `block`.  `nil` when transaction is pending or has only been collated into
     one of the `uncles` in one of the `forks`.
    * `created_contract_address_hash` - This transaction deployed contract address.
    * `native_transfer_address_hash` - If this transaction is native transfer, to_address is a contract, this column is actual receiver.
    * `tx_hash` - The transaction foreign key.
  """
  @type t :: %__MODULE__{
          is_create: boolean(),
          gas_limit: Decimal.t(),
          gas_price: Decimal.t(),
          gas_used: Decimal.t(),
          value: Decimal.t(),
          input: Data.t(),
          input_size: non_neg_integer(),
          transaction_index: non_neg_integer(),
          created_contract_address_hash: Hash.Address.t(),
          native_transfer_address_hash: Hash.Address.t(),
          status: String.t(),
          tx_hash: Hash.Full.t(),
          transaction: %Ecto.Association.NotLoaded{} | Transaction.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "polyjuices" do
    field(:is_create, :boolean, default: false)
    field(:gas_limit, :decimal)
    field(:gas_price, :decimal)
    field(:gas_used, :decimal)
    field(:value, :decimal)
    field(:input_size, :integer)
    field(:input, Data)

    field(:transaction_index, :integer)
    field(:created_contract_address_hash, Hash.Address)
    field(:status, Ecto.Enum, values: [:succeed, :failed])

    field(:call_contract, Hash.Address)
    field(:call_data, Data)
    field(:call_gas_limit, :decimal)
    field(:verification_gas_limit, :decimal)
    field(:max_fee_per_gas, :decimal)
    field(:max_priority_fee_per_gas, :decimal)
    field(:paymaster_and_data, Data)

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      type: Hash.Full
    )

    belongs_to(:native_transfer_account, GodwokenExplorer.Account,
      foreign_key: :native_transfer_address_hash,
      references: :eth_address,
      type: Hash.Address
    )

    timestamps()
  end

  @doc false
  def changeset(polyjuice, attrs) do
    polyjuice
    |> cast(attrs, [
      :is_create,
      :gas_limit,
      :gas_price,
      :value,
      :input_size,
      :input,
      :gas_used,
      :transaction_index,
      :status,
      :created_contract_address_hash,
      :tx_hash,
      :native_transfer_address_hash,
      :call_contract,
      :call_data,
      :call_gas_limit,
      :verification_gas_limit,
      :max_fee_per_gas,
      :max_priority_fee_per_gas,
      :paymaster_and_data
    ])
    |> validate_required([
      :tx_hash,
      :is_create,
      :gas_limit,
      :gas_price,
      :value,
      :input_size,
      :input
    ])
    |> unique_constraint(:tx_hash)
  end

  def create_polyjuice(attrs) do
    %Polyjuice{}
    |> Polyjuice.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Repo.insert(on_conflict: :nothing)
  end

  def get_method_name(to_account_id, input, hash \\ "")

  def get_method_name(_to_account_id, nil, _hash), do: nil

  def get_method_name(to_account_id, input, hash) do
    case decode_input(to_account_id, input, hash) do
      {:ok, _, decoded_func, _} ->
        parse_method_name(decoded_func)

      _ ->
        nil
    end
  end

  def get_method_name_without_account_check(to_account_id, input, hash \\ "") do
    case decode_input_without_account_check(to_account_id, input, hash) do
      {:ok, _, decoded_func, _} ->
        parse_method_name(decoded_func)

      _ ->
        nil
    end
  end

  def decode_transfer_args(to_account_id, input, hash \\ "") do
    case decode_input(to_account_id, input, hash) do
      {:ok, _method_sign, method_desc, args} ->
        method_name = parse_method_name(method_desc)

        if method_name == "Transfer" do
          Polyjuice.parse_transfer_args(args)
        else
          {nil, nil}
        end

      _ ->
        {nil, nil}
    end
  end

  def decode_input_without_account_check(to_account_id, input, hash) do
    full_abi = SmartContract.cache_abi(to_account_id)

    case do_decoded_input_data(
           Base.decode16!(String.slice(input, 2..-1), case: :lower),
           full_abi,
           hash
         ) do
      {:ok, identifier, text, mapping} ->
        {:ok, identifier, text, mapping}

      _ ->
        {:error, :decode_error}
    end
  end

  def decode_input(to_account_id, input, hash) do
    q = from(sc in SmartContract, where: sc.account_id == ^to_account_id)

    if Repo.exists?(q) do
      decode_input_without_account_check(to_account_id, input, hash)
    else
      {:error, :decode_error}
    end
  end

  def parse_transfer_args(args) do
    {"0x" <> (args |> List.first() |> elem(2) |> Base.encode16(case: :lower)),
     args |> List.last() |> elem(2)}
  end

  #  {:ok, "a9059cbb", "transfer(address _to, uint256 _value)",
  #  [
  #    {"_to", "address",
  #      <<84, 194, 168, 114, 226, 215, 140, 253, 44, 95, 160, 152, 61, 61, 77, 139,
  #        251, 26, 202, 98>>},
  #    {"_value", "uint256", 1000000000}
  #  ]}
  defp do_decoded_input_data(data, full_abi, hash) do
    with {:ok, {selector, values}} <- find_and_decode(full_abi, data, hash),
         {:ok, mapping} <- selector_mapping(selector, values, hash),
         identifier <- Base.encode16(selector.method_id, case: :lower),
         text <- function_call(selector.function, mapping),
         do: {:ok, identifier, text, mapping}
  end

  defp function_call(name, mapping) do
    text =
      mapping
      |> Stream.map(fn {name, type, _} -> [type, " ", name] end)
      |> Enum.intersperse(", ")

    IO.iodata_to_binary([name, "(", text, ")"])
  end

  defp find_and_decode(abi, data, hash) do
    result =
      abi
      |> ABI.parse_specification()
      |> ABI.find_and_decode(data)

    {:ok, result}
  rescue
    _ ->
      Logger.debug(fn ->
        "Could not find_and_decode input data for transaction: #{inspect(hash)}"
      end)

      {:error, :could_not_decode}
  end

  defp selector_mapping(selector, values, hash) do
    types = Enum.map(selector.types, &FunctionSelector.encode_type/1)

    mapping = Enum.zip([selector.input_names, types, values])

    {:ok, mapping}
  rescue
    _ ->
      Logger.warn(fn -> ["Could not decode input data for transaction: ", hash] end)
      {:error, :could_not_decode}
  end

  def parse_method_name(method_desc) do
    method_desc
    |> String.split("(")
    |> Enum.at(0)
    |> upcase_first
  end

  defp upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest
end
