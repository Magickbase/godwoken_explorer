defmodule GodwokenExplorer.TokenTransferFactory do
  alias GodwokenExplorer.TokenTransfer
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def token_transfer_factory do
        %TokenTransfer{
          amount: D.new(1_709_736_523_257_224_194),
          amounts: nil,
          block: build(:block),
          block_number: block_number(),
          from_address_hash: "0x297ce8d1532704f7be447bc897ab63563d60f223",
          log_index: 3,
          to_address_hash: "0xf00b259ed79bb80291b45a76b13e3d71d4869433",
          token_contract_address_hash: "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
          token_id: nil,
          token_ids: nil,
          transaction: build(:transaction)
        }
      end

      def token_transfer_erc1155_inserted_factory do
        %TokenTransfer{
          amount: D.new(1_709_736_523_257_224_194),
          amounts: nil,
          block: insert(:block),
          block_number: block_number(),
          from_address_hash: "0x297ce8d1532704f7be447bc897ab63563d60f223",
          log_index: 3,
          to_address_hash: "0xf00b259ed79bb80291b45a76b13e3d71d4869433",
          token_contract_address_hash: "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
          token_id: nil,
          token_ids: [1, 2],
          transaction: insert(:transaction)
        }
      end

      def token_transfer_erc721_inserted_factory do
        %TokenTransfer{
          amount: D.new(1_709_736_523_257_224_194),
          amounts: nil,
          block: insert(:block),
          block_number: block_number(),
          from_address_hash: "0x297ce8d1532704f7be447bc897ab63563d60f223",
          log_index: 3,
          to_address_hash: "0xf00b259ed79bb80291b45a76b13e3d71d4869433",
          token_contract_address_hash: "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
          token_id: 1,
          token_ids: nil,
          transaction: insert(:transaction)
        }
      end

      def token_transfer_erc20_inserted_factory do
        %TokenTransfer{
          amount: D.new(1_709_736_523_257_224_194),
          amounts: nil,
          block: insert(:block),
          block_number: block_number(),
          from_address_hash: "0x297ce8d1532704f7be447bc897ab63563d60f223",
          log_index: 3,
          to_address_hash: "0xf00b259ed79bb80291b45a76b13e3d71d4869433",
          token_contract_address_hash: "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
          token_id: nil,
          token_ids: nil,
          transaction: insert(:transaction)
        }
      end
    end
  end
end
