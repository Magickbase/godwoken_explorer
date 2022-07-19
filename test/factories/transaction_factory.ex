defmodule GodwokenExplorer.TransactionFactory do
  alias GodwokenExplorer.{Transaction, Repo}

  defmacro __using__(_opts) do
    quote do
      def transaction_factory do
        block = build(:block)

        %Transaction{
          from_account: build(:user),
          to_account: build(:polyjuice_contract_account),
          args:
            "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000",
          hash: transaction_hash(),
          eth_hash: transaction_hash(),
          nonce: Enum.random(1..1_000),
          type: :polyjuice,
          block: block,
          block_number: block.number,
          index: sequence("transaction", & &1)
        }
      end

      def with_polyjuice(%Transaction{} = transaction) do
        insert(:polyjuice, transaction: transaction)
        transaction
      end

      def polyjuice_creator_tx_factory do
        %Transaction{
          from_account: build(:user),
          to_account: build(:meta_contract),
          args:
            "0x00000000790000000c0000006500000059000000100000003000000031000000636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8012400000040d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b010000000100000001000000000000000000000000000000",
          hash: transaction_hash(),
          nonce: Enum.random(1..1_000),
          type: :polyjuice_creator,
          index: sequence("transaction", & &1)
        }
      end

      def with_block(%Transaction{index: nil} = transaction) do
        {:ok, block} = insert(:block)

        transaction
        |> Transaction.changeset(%{block_hash: block.hash, block_number: block.number})
        |> Repo.update!()
        |> Repo.preload(:block)
      end
    end
  end
end
