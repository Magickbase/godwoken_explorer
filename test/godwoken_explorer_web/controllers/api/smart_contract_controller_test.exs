defmodule GodwokenExplorerWeb.API.SmartContractControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import Mock

  setup do
    account = insert(:polyjuice_contract_account)
    contract = insert(:smart_contract, account: account)
    %{contract: contract}
  end

  describe "index" do
    test "return all smart_contracts", %{conn: conn, contract: contract} do
      with_mocks([
        {GodwokenExplorer.UDT, [],
         ckb_account_id: fn ->
           1
         end},
        {GodwokenRPC, [],
         fetch_balance: fn _, _ ->
           {:ok, 1000000_000}
         end}
      ]) do
        conn =
          get(
            conn,
            ~p"/api/smart_contracts"
          )

        assert json_response(conn, 200) == %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "balance" => "10",
                       "compiler_file_format" => nil,
                       "compiler_version" => nil,
                       "deployment_tx_hash" => to_string(contract.deployment_tx_hash),
                       "eth_address" => to_string(contract.account.eth_address),
                       "id" => contract.id,
                       "name" => contract.name,
                       "other_info" => nil,
                       "tx_count" => 0
                     },
                     "id" => to_string(contract.id),
                     "relationships" => %{},
                     "type" => "smart_contract"
                   }
                 ],
                 "included" => [],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
      end
    end
  end
end
