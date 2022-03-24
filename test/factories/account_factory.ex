defmodule GodwokenExplorer.AccountFactory do
  alias GodwokenExplorer.Account

  defmacro __using__(_opts) do
    quote do
      def meta_contract_factory do
        %Account{
          id: 0,
          nonce: 0,
          script_hash: "0x5c84fc6078725df72052cc858dffc6f352a069706c9023a82eeff3b2a1a9ccd1",
          short_address: "0x5c84fc6078725df72052cc858dffc6f352a06970",
          type: :meta_contract
        }
      end

      def ckb_account_factory do
        %Account{
          id: 1,
          type: :udt,
          short_address: "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
          script_hash: "0x9e9c54293c3211259de788e97a31b5b3a66cd53564f8d39dfabdc8e96cdf5ea4"
        }
      end
    end
  end
end
