defmodule GodwokenExplorer.AccountFactory do
  alias GodwokenExplorer.Account

  defmacro __using__(_opts) do
    quote do
      def meta_contract_factory do
        %Account{
          id: 0,
          nonce: 0,
          script_hash: "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
          type: :meta_contract
        }
      end

      def ckb_account_factory do
        %Account{
          id: 1,
          type: :udt,
          script_hash: "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
          registry_address: "0x9e9c54293c3211259de788e97a31b5b3a66cd535"
        }
      end

      def block_producer_factory do
        %Account{
          id: 3,
          type: :eth_user,
          script_hash: "0x495d9cfb7b6faeaeb0f5a7ed81a830a477f7aeea8d53ef73abdc2ec2f5fed07c",
          registry_address: "0x0200000014000000715ab282b873b79a7be8b0e8c13c4e8966a52040",
          eth_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040"
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
          token_transfer_count: 0,
          contract_code: data(:contract_code)
        }
      end

      def polyjuice_creator_account_factory do
        %Account{
          id: 4,
          script_hash: block_hash(),
          type: :polyjuice_creator
        }
      end
    end
  end
end
