defmodule GodwokenExplorer.VersionFactory do
  alias GodwokenExplorer.Version

  defmacro __using__(_opts) do
    quote do
      def version_factory do
        %Version{
          patch: %{
            block_hash:
              {:changed,
               {:primitive_change,
                "0x874ea1f3ce253a8ad2f6d099490913dd7dd8412f50059ff0d62b7475aea789a1",
                "0xdd722f6d2aa83c9733f0c7dfdcffb89560c7ac39c999db9d747d00ce081086d9"}},
            tip_block_number: {:changed, {:primitive_change, 7_655_429, 7_655_430}},
            updated_at: {:changed, %{second: {:changed, {:primitive_change, 29, 45}}}}
          },
          entity_id: 1,
          entity_schema: GodwokenExplorer.CheckInfo,
          action: :updated,
          recorded_at: DateTime.utc_now(),
          rollback: false
        }
      end
    end
  end
end
