defmodule GodwokenIndexer.Transform.TokenApprovals do
  import GodwokenRPC.Util,
    only: [
      hex_to_number: 1
    ]

  alias GodwokenExplorer.{Repo, UDT}

  @approval_event "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
  @approval_for_all_event "0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31"
  @zero_address "0x0000000000000000000000000000000000000000000000000000000000000000"

  def parse(logs) do
    initial_acc = %{approval_erc20: [], approval_erc721: []}

    approval_events =
      logs
      |> Enum.filter(&(&1.first_topic == @approval_event))
      |> Enum.reduce(initial_acc, fn log,
                                     %{
                                       approval_erc20: erc20_tokens,
                                       approval_erc721: erc721_tokens
                                     } ->
        case Repo.get_by(UDT, contract_address_hash: log.address_hash) do
          %{eth_type: :erc20} ->
            approved = log.data |> to_string() != @zero_address

            params = %{
              block_hash: log.block_hash,
              block_number: log.block_number,
              transaction_hash: log.transaction_hash,
              token_owner_address_hash: parse_address(log.second_topic),
              spender_address_hash: parse_address(log.third_topic),
              token_contract_address_hash: log.address_hash |> to_string(),
              data: log.data |> to_string() |> hex_to_number(),
              approved: approved,
              type: :approval,
              token_type: :erc20
            }

            %{approval_erc20: [params | erc20_tokens], approval_erc721: erc721_tokens}

          %{eth_type: :erc721} ->
            approved = log.third_topic != @zero_address

            params = %{
              block_hash: log.block_hash,
              block_number: log.block_number,
              transaction_hash: log.transaction_hash,
              token_owner_address_hash: parse_address(log.second_topic),
              spender_address_hash: parse_address(log.third_topic),
              token_contract_address_hash: log.address_hash |> to_string(),
              data: log.data |> to_string() |> hex_to_number(),
              approved: approved,
              type: :approval,
              token_type: :erc721
            }

            %{approval_erc20: erc20_tokens, approval_erc721: [params | erc721_tokens]}

          _ ->
            %{approval_erc20: erc20_tokens, approval_erc721: erc721_tokens}
        end
      end)

    approval_all_events =
      logs
      |> Enum.filter(&(&1.first_topic == @approval_for_all_event))
      |> Enum.map(fn log ->
        approved =
          if log.data |> to_string() ==
               "0x0000000000000000000000000000000000000000000000000000000000000001",
             do: true,
             else: false

        %{
          block_number: log.block_number,
          block_hash: log.block_hash,
          transaction_hash: log.transaction_hash,
          token_owner_address_hash: parse_address(log.second_topic),
          spender_address_hash: parse_address(log.third_topic),
          token_contract_address_hash: log.address_hash |> to_string(),
          data: log.data |> to_string() |> hex_to_number(),
          approved: approved,
          type: :approval_all
        }
      end)

    approval_events |> Map.put(:approval_all_tokens, approval_all_events)
  end

  defp parse_address(topic) do
    "0x" <> (topic |> String.slice(-40..-1))
  end
end
