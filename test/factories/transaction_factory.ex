defmodule GodwokenExplorer.TransactionFactory do
  alias GodwokenExplorer.Transaction

  defmacro __using__(_opts) do
    quote do
      def transaction_factory do
        %Transaction{
          args: "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000",
          from_account_id: 2,
          hash:
            sequence(:hash, &"0x#{&1}b6c0a6f68c929453197ca43b06b4735e4c04b105b9418954aae9240bfa7330",
              start_at: 100
            ),
          block_number: sequence(:block_number, & &1, start_at: 100),
          nonce: sequence(:nonce, & &1, start_at: 0),
          to_account_id: 6,
          type: :sudt
        }
      end
    end
  end
end
