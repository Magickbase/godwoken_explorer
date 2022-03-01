defmodule GodwokenExplorer.PendingTransaction do
  use GodwokenExplorer, :schema
  use Retry

  import GodwokenRPC.Util, only: [hex_to_number: 1, parse_le_number: 1, transform_hash_type: 1, parse_polyjuice_args: 1]
  import Godwoken.MoleculeParser, only: [parse_meta_contract_args: 1]

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:hash, :binary, autogenerate: false}
  schema "pending_transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :to_account_id, :integer
    field :type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice]
    field :parsed_args, :map

    timestamps()
  end

  @doc false
  def changeset(pending_transaction, attrs) do
    pending_transaction
    |> cast(attrs, [:hash, :from_account_id, :to_account_id, :nonce, :args, :type, :parsed_args])
    |> validate_required([:hash, :from_account_id, :to_account_id, :nonce, :args, :type, :parsed_args])
  end

  def create_pending_transaction(attrs) do
    %PendingTransaction{}
    |> PendingTransaction.changeset(attrs)
    |> Repo.insert([on_conflict: :nothing])
  end

  def find_by_hash(tx_hash) do
    case pending_tx = Repo.get_by(PendingTransaction, hash: tx_hash) do
      %__MODULE__{} ->
        pending_tx
      nil ->
        retry with: constant_backoff(500) |> Stream.take(3) do
          case GodwokenRPC.fetch_mempool_transaction(tx_hash) do
            {:ok, response} when is_nil(response) ->
              nil
            {:ok, response} ->
              {:ok, tx} =
                response["transaction"]["raw"]
                |> parse_raw()
                |> Map.merge(%{hash: tx_hash})
                |> create_pending_transaction()

              tx
            {:error, msg} ->
              {:error, msg}
          end
        after
          result -> result
        else
          _error -> nil
        end
    end
  end

  def parse_raw(%{
      "from_id" => from_account_id,
      "to_id" => to_account_id,
      "nonce" => nonce,
      "args" => "0x" <> args
    }) when to_account_id == "0x0" do
      {{code_hash, hash_type, script_args}, {fee_sudt_id, fee_amount_hex_string}} =
        parse_meta_contract_args(args)

      fee_amount = fee_amount_hex_string |> parse_le_number()
      from_account_id = hex_to_number(from_account_id)
    %{
      nonce: hex_to_number(nonce),
      args: "0x" <> args,
      from_account_id: from_account_id,
      to_account_id: hex_to_number(to_account_id),
      type: :polyjuice_creator,
      parsed_args: %{
        code_hash: "0x" <> code_hash,
        hash_type: transform_hash_type(hash_type),
        fee_udt_id: fee_sudt_id,
        fee_amount: fee_amount,
        script_args: script_args
      }
    }
  end

  def parse_raw(%{
      "from_id" => from_account_id,
      "to_id" => to_id,
      "nonce" => nonce,
      "args" => "0x" <> args
      }) do
    if String.starts_with?(args, "ffffff504f4c59") do
      [is_create, gas_limit, gas_price, value, input_size, input] = parse_polyjuice_args(args)

      from_account_id = hex_to_number(from_account_id)
      to_account_id = hex_to_number(to_id)

      %{
        type: :polyjuice,
        nonce: hex_to_number(nonce),
        args: "0x" <> args,
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        parsed_args: %{
          is_create: is_create,
          gas_limit: gas_limit,
          gas_price: gas_price,
          value: value,
          input_size: input_size,
          input: input
        }
      }
    end
  end
end
