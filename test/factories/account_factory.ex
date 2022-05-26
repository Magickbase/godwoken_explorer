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

      def ckb_contract_account_factory do
        %Account{
          id: 247,
          type: :polyjuice_contract,
          short_address: "0x9d9599c41383d7009c2093319d576aa6f89a4449",
          script_hash: "0x9d9599c41383d7009c2093319d576aa6f89a4449467441966352bb62e12001d3"
        }
      end

      def user_factory do
        %Account{
          id: sequence(:id, & &1, start_at: 1000),
          eth_address: address_hash(),
          script_hash: block_hash(),
          short_address: address_hash(),
          type: :user
        }
      end

      def polyjuice_contract_factory do
        %Account{
          id: sequence(:id, & &1, start_at: 2000),
          script_hash: block_hash(),
          short_address: address_hash(),
          type: :polyjuice_contract
        }
      end
    end
  end
end
