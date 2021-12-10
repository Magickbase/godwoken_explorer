defmodule GodwokenExplorer.Polyjuice do
  use GodwokenExplorer, :schema
  use Retry

  import Ecto.Changeset

  require Logger

  alias ABI.FunctionSelector

  schema "polyjuice" do
    field :is_create, :boolean, default: false
    field :gas_limit, :integer
    field :gas_price, :decimal
    field :value, :decimal
    field :input_size, :integer
    field :input, :binary
    field :tx_hash, :binary
    field :gas_used, :integer
    field :receive_address, :binary
    field :receive_eth_address, :binary
    field :transfer_count, :decimal

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      define_field: false
    )

    timestamps()
  end

  @doc false
  def changeset(polyjuice, attrs) do
    polyjuice
    |> cast(attrs, [:is_create, :gas_limit, :gas_price, :value, :input_size, :input, :gas_used, :receive_address, :transfer_count, :receive_eth_address])
    |> validate_required([:is_create, :gas_limit, :gas_price, :value, :input_size, :input])
  end

  def create_polyjuice(attrs) do
    gas_used =
      retry with: constant_backoff(500) |> Stream.take(3) do
        case GodwokenRPC.fetch_receipt(attrs[:hash]) do
          {:ok, gas_used} ->
            gas_used

          {:error, _} ->
            {:error, :node_error}
        end
      after
        result -> result
      else
        _error -> nil
      end

    {short_address, transfer_count} = decode_transfer_args(attrs[:to_account_id], attrs[:input], attrs[:hash])

    eth_address =
      if short_address do
        AccountUDT.update_erc20_balance(attrs[:to_account_id], attrs[:from_account_id])

        case Account |> Repo.get_by(short_address: short_address) do
          nil -> nil
          %Account{id: id, eth_address: eth_address} ->
            AccountUDT.update_erc20_balance(attrs[:to_account_id], id)
            eth_address
        end
      end

    %Polyjuice{}
    |> Polyjuice.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Ecto.Changeset.put_change(:gas_used, gas_used)
    |> Ecto.Changeset.put_change(:receive_address, short_address)
    |> Ecto.Changeset.put_change(:receive_eth_address, eth_address)
    |> Ecto.Changeset.put_change(:transfer_count, transfer_count)
    |> Repo.insert()
  end

  def get_method_name(to_account_id, input, hash \\ "") do
    case decode_input(to_account_id, input, hash) do
      {:ok, _, decoded_func, _} ->
        parse_method_name(decoded_func)
      nil ->
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

  defp decode_input(to_account_id, input, hash) do
      with  %SmartContract{abi: full_abi} <- Repo.get_by(SmartContract, account_id: to_account_id) do
      do_decoded_input_data(
        Base.decode16!(String.slice(input, 2..-1), case: :lower),
        full_abi,
        hash
      )
    else
      _ ->
        Logger.error("decord input data failed #{hash}")
        nil
    end
  end

  def parse_transfer_args(args) do
    {"0x" <> (args |> List.first() |> elem(2) |> Base.encode16(case: :lower)), args |> List.last() |> elem(2)}
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
