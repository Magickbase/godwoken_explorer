defmodule GodwokenExplorer.AccountFactory do
  alias GodwokenExplorer.Account

  defmacro __using__(_opts) do
    quote do
      def meta_contract_factory do
        %Account{
          id: 0,
          nonce: 0,
          script_hash: block_hash(),
          type: :meta_contract
        }
      end

      def ckb_account_factory do
        %Account{
          id: 1,
          type: :udt,
          script_hash: block_hash(),
          registry_address: "0x9e9c54293c3211259de788e97a31b5b3a66cd535"
        }
      end

      def ckb_contract_account_factory do
        %Account{
          id: 247,
          type: :polyjuice_contract,
          script_hash: block_hash(),
          eth_address: address_hash()
        }
      end

      def user_factory do
        %Account{
          id: sequence(:id, & &1, start_at: 1000),
          eth_address: address_hash(),
          script_hash: block_hash(),
          type: :eth_user,
          nonce: sequence(:nonce, & &1, start_at: 0)
        }
      end

      def polyjuice_contract_account_factory do
        %Account{
          id: sequence(:id, & &1, start_at: 2000),
          script_hash: block_hash(),
          type: :polyjuice_contract,
          eth_address: address_hash(),
          token_transfer_count: 0
        }
      end

      def polyjuice_creator_account_factory do
        %Account{
          id: 3,
          script_hash: block_hash(),
          type: :polyjuice_creator
        }
      end
    end
  end
end
