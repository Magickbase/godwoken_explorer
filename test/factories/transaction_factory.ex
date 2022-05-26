defmodule GodwokenExplorer.TransactionFactory do
  alias GodwokenExplorer.{Transaction, Repo}

  defmacro __using__(_opts) do
    quote do
      def transaction_factory do
        %Transaction{
          from_account: build(:user),
          to_account: build(:polyjuice_contract),
          args:
            "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000",
          hash: transaction_hash(),
          nonce: Enum.random(1..1_000),
          type: :polyjuice
        }
      end

      def with_polyjuice(%Transaction{} = transaction) do
        insert(:polyjuice, transaction: transaction)
        transaction
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
