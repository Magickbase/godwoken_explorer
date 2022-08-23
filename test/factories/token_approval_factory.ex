defmodule GodwokenExplorer.TokenApprovalFactory do
  alias GodwokenExplorer.TokenApproval

  defmacro __using__(_opts) do
    quote do
      def approval_token_approval_factory do
        block = build(:block)

        %TokenApproval{
          id: sequence(:id, & &1),
          block_hash: block.hash,
          block_number: block.number,
          transaction_hash: build(:transaction).eth_hash,
          token_contract_address_hash: address_hash(),
          token_owner_address_hash: address_hash(),
          spender_address_hash: address_hash() |> to_string(),
          data: 0,
          approved: true,
          type: :approval
        }
      end

      def approval_all_token_approval_factory do
        block = build(:block)

        %TokenApproval{
          id: sequence(:id, & &1),
          block_hash: block.hash,
          block_number: block.number,
          transaction_hash: build(:transaction).eth_hash,
          token_contract_address_hash: address_hash(),
          token_owner_address_hash: address_hash(),
          spender_address_hash: address_hash() |> to_string(),
          data: 1,
          approved: true,
          type: :approval_all
        }
      end
    end
  end
end
