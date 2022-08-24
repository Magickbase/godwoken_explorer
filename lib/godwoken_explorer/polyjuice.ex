defmodule GodwokenExplorer.Polyjuice do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  require Logger

  alias ABI.FunctionSelector
  alias GodwokenExplorer.Chain.{Data, Hash}

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "polyjuices" do
    field :is_create, :boolean, default: false
    field :gas_limit, :decimal
    field :gas_price, :decimal
    field :value, :decimal
    field :input_size, :integer
    field :input, Data
    field :gas_used, :decimal
    field :transaction_index, :integer
    field :created_contract_address_hash, Hash.Address
    field(:status, Ecto.Enum, values: [:succeed, :failed])

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      type: Hash.Full
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
      :tx_hash
    ])
    |> validate_required([
      :tx_hash,
      :is_create,
      :gas_limit,
      :gas_price,
      :value,
      :input_size,
      :input,
      :transaction_index
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

  def decode_input(to_account_id, input, hash) do
    if to_account_id in SmartContract.account_ids() do
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
      Logger.warn(fn -> ["Could not find_and_decode input data for transaction: ", hash] end)
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
