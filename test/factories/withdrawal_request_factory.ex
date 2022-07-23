defmodule GodwokenExplorer.WithdrawalRequestFactory do
  alias GodwokenExplorer.WithdrawalRequest
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def withdrawal_request_factory do
        %WithdrawalRequest{
          account_script_hash: block_hash(),
          amount: D.new(0),
          block_hash: block_hash(),
          capacity: D.new(383_220_966_182),
          fee_amount: D.new(0),
          nonce: 0,
          owner_lock_hash: block_hash(),
          sudt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          udt_id: 1,
          registry_id: 3
        }
      end
    end
  end
end
