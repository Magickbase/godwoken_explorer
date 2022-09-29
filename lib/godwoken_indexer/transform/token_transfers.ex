defmodule GodwokenIndexer.Transform.TokenTransfers do
  @moduledoc """
  Helper functions for transforming data for ERC-20 and ERC-721 token transfers.
  """
  import Ecto.Query

  require Logger

  alias GodwokenExplorer.{Chain, Repo, UDT}
  alias ABI.TypeDecoder
  alias GodwokenExplorer.{TokenApproval, TokenTransfer}
  alias GodwokenExplorer.Token.MetadataRetriever

  @burn_address "0x0000000000000000000000000000000000000000"

  @doc """
  Returns a list of token transfers given a list of logs.
  """
  def parse(logs) do
    initial_acc = %{tokens: [], token_transfers: []}

    erc20_and_erc721_token_transfers =
      logs
      |> Enum.filter(&(&1.first_topic == unquote(TokenTransfer.constant())))
      |> Enum.reduce(initial_acc, &do_parse/2)

    erc1155_token_transfers =
      logs
      |> Enum.filter(fn log ->
        log.first_topic == TokenTransfer.erc1155_single_transfer_signature() ||
          log.first_topic == TokenTransfer.erc1155_batch_transfer_signature()
      end)
      |> Enum.reduce(initial_acc, &do_parse(&1, &2, :erc1155))

    tokens = erc1155_token_transfers.tokens ++ erc20_and_erc721_token_transfers.tokens

    token_transfers =
      erc1155_token_transfers.token_transfers ++ erc20_and_erc721_token_transfers.token_transfers

    token_transfers
    |> Enum.filter(fn token_transfer ->
      token_transfer.to_address_hash == @burn_address ||
        token_transfer.from_address_hash == @burn_address
    end)
    |> Enum.map(fn token_transfer ->
      token_transfer.token_contract_address_hash
    end)
    |> Enum.uniq()
    |> Enum.each(&update_token/1)

    tokens_uniq = tokens |> Enum.uniq()

    token_transfers_from_logs_uniq = %{
      tokens: tokens_uniq,
      token_transfers: token_transfers
    }

    token_transfers_from_logs_uniq
  end

  defp do_parse(
         log,
         %{tokens: tokens, token_transfers: token_transfers} = acc,
         type \\ :erc20_erc721
       ) do
    {token, token_transfer} =
      if type != :erc1155 do
        parse_params(log)
      else
        parse_erc1155_params(log)
      end

    %{
      tokens: [token | tokens],
      token_transfers: [token_transfer | token_transfers]
    }
  rescue
    _ in [FunctionClauseError, MatchError] ->
      Logger.error(fn -> "Unknown token transfer format: #{inspect(log)}" end)
      acc
  end

  # ERC-20 token transfer
  defp parse_params(
         %{second_topic: second_topic, third_topic: third_topic, fourth_topic: nil} = log
       )
       when not is_nil(second_topic) and not is_nil(third_topic) do
    [amount] = decode_data(log.data, [{:uint, 256}])

    token_transfer = %{
      amount: Decimal.new(amount || 0),
      block_number: log.block_number,
      block_hash: log.block_hash,
      log_index: log.index,
      from_address_hash: truncate_address_hash(log.second_topic),
      to_address_hash: truncate_address_hash(log.third_topic),
      token_contract_address_hash: log.address_hash,
      transaction_hash: log.transaction_hash,
      token_id: nil,
      token_type: :erc20
    }

    token = %{
      contract_address_hash: log.address_hash,
      eth_type: :erc20
    }

    {token, token_transfer}
  end

  # ERC-721 token transfer with topics as addresses
  defp parse_params(
         %{second_topic: second_topic, third_topic: third_topic, fourth_topic: fourth_topic} = log
       )
       when not is_nil(second_topic) and not is_nil(third_topic) and not is_nil(fourth_topic) do
    [token_id] = decode_data(fourth_topic, [{:uint, 256}])

    token_transfer = %{
      block_number: log.block_number,
      log_index: log.index,
      block_hash: log.block_hash,
      from_address_hash: truncate_address_hash(log.second_topic),
      to_address_hash: truncate_address_hash(log.third_topic),
      token_contract_address_hash: log.address_hash,
      token_id: token_id || 0,
      token_type: :erc721,
      transaction_hash: log.transaction_hash
    }

    token = %{
      contract_address_hash: log.address_hash,
      eth_type: :erc721
    }

    delete_token_approval(
      token_transfer[:from_address_hash],
      token_transfer[:token_contract_address_hash],
      token_transfer[:token_id]
    )

    {token, token_transfer}
  end

  # ERC-721 token transfer with info in data field instead of in log topics
  defp parse_params(
         %{
           second_topic: nil,
           third_topic: nil,
           fourth_topic: nil,
           data: data
         } = log
       )
       when not is_nil(data) do
    [from_address_hash, to_address_hash, token_id] =
      decode_data(data, [:address, :address, {:uint, 256}])

    token_transfer = %{
      block_number: log.block_number,
      block_hash: log.block_hash,
      log_index: log.index,
      from_address_hash: encode_address_hash(from_address_hash),
      to_address_hash: encode_address_hash(to_address_hash),
      token_contract_address_hash: log.address_hash,
      token_id: token_id,
      token_type: :erc721,
      transaction_hash: log.transaction_hash
    }

    token = %{
      contract_address_hash: log.address_hash,
      eth_type: :erc721
    }

    delete_token_approval(
      token_transfer[:from_address_hash],
      token_transfer[:token_contract_address_hash],
      token_transfer[:token_id]
    )

    {token, token_transfer}
  end

  defp delete_token_approval(owner_address_hash, token_contract_address_hash, token_id) do
    from(ta in TokenApproval,
      where:
        ta.token_owner_address_hash == ^owner_address_hash and
          ta.token_contract_address_hash == ^token_contract_address_hash and ta.data == ^token_id
    )
    |> Repo.delete_all()
  end

  defp update_token(nil), do: :ok

  defp update_token(address_hash_string) do
    {:ok, address_hash} = Chain.string_to_address_hash(address_hash_string)

    udt = Repo.get_by(UDT, contract_address_hash: address_hash)

    if udt && !udt.skip_metadata do
      udt_to_update = udt |> Repo.preload([:account])

      token_params = address_hash_string |> MetadataRetriever.get_total_supply_of()

      if token_params !== %{} do
        {:ok, _} =
          Chain.update_udt(
            %{
              udt_to_update
              | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
            },
            token_params
          )
      end
    end

    :ok
  end

  def parse_erc1155_params(
        %{
          first_topic: unquote(TokenTransfer.erc1155_batch_transfer_signature()),
          third_topic: third_topic,
          fourth_topic: fourth_topic,
          data: data
        } = log
      ) do
    [token_ids, values] = decode_data(data, [{:array, {:uint, 256}}, {:array, {:uint, 256}}])

    token_transfer = %{
      block_number: log.block_number,
      block_hash: log.block_hash,
      log_index: log.index,
      from_address_hash: truncate_address_hash(third_topic),
      to_address_hash: truncate_address_hash(fourth_topic),
      token_contract_address_hash: log.address_hash,
      transaction_hash: log.transaction_hash,
      token_ids: token_ids,
      token_id: nil,
      token_type: :erc1155,
      amounts: values
    }

    token = %{
      contract_address_hash: log.address_hash,
      eth_type: :erc1155
    }

    {token, token_transfer}
  end

  def parse_erc1155_params(
        %{third_topic: third_topic, fourth_topic: fourth_topic, data: data} = log
      ) do
    [token_id, value] = decode_data(data, [{:uint, 256}, {:uint, 256}])

    token_transfer = %{
      amount: value,
      block_number: log.block_number,
      block_hash: log.block_hash,
      log_index: log.index,
      from_address_hash: truncate_address_hash(third_topic),
      to_address_hash: truncate_address_hash(fourth_topic),
      token_contract_address_hash: log.address_hash,
      transaction_hash: log.transaction_hash,
      token_id: token_id,
      token_type: :erc1155
    }

    token = %{
      contract_address_hash: log.address_hash,
      eth_type: :erc1155
    }

    {token, token_transfer}
  end

  defp truncate_address_hash(nil), do: "0x0000000000000000000000000000000000000000"

  defp truncate_address_hash("0x000000000000000000000000" <> truncated_hash) do
    "0x#{truncated_hash}"
  end

  defp encode_address_hash(binary) do
    "0x" <> Base.encode16(binary, case: :lower)
  end

  defp decode_data("0x", types) do
    for _ <- types, do: nil
  end

  defp decode_data("0x" <> encoded_data, types) do
    encoded_data
    |> Base.decode16!(case: :mixed)
    |> TypeDecoder.decode_raw(types)
  end
end
