defmodule GodwokenExplorer.CurrentBridgedUDTBalanceFactory do
  alias GodwokenExplorer.Account.CurrentBridgedUDTBalance

  defmacro __using__(_opts) do
    quote do
      def current_bridged_udt_balance_factory do
        %CurrentBridgedUDTBalance{
          address_hash: address_hash(),
          udt_id: sequence(:udt_id, & &1, start_at: 1),
          udt_script_hash: udt_script_hash(),
          value: Enum.random(1..100_000)
        }
      end
    end
  end
end
