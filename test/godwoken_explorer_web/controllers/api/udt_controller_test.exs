defmodule GodwokenExplorerWeb.API.UDTControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    udt_account = insert(:polyjuice_contract_account)

    native_udt =
      insert(:native_udt, id: udt_account.id, contract_address_hash: udt_account.eth_address)

    %{udt: native_udt, udt_account: udt_account}
  end

  describe "index" do
    test "return list", %{conn: conn, udt: udt} do
      conn =
        get(
          conn,
          ~p"/api/udts?type=native"
        )

      assert json_response(conn, 200) == %{
               "data" => [
                 %{
                   "attributes" => %{
                     "decimal" => udt.decimal,
                     "description" => udt.description,
                     "eth_address" => to_string(udt.contract_address_hash),
                     "holder_count" => 0,
                     "icon" => udt.icon,
                     "id" => udt.id,
                     "name" => udt.name,
                     "official_site" => udt.official_site,
                     "supply" => udt.supply |> Decimal.to_string(),
                     "symbol" => udt.symbol,
                     "transfer_count" => 0,
                     "type" => to_string(udt.type)
                   },
                   "id" => to_string(udt.id),
                   "relationships" => %{},
                   "type" => "udt"
                 }
               ],
               "included" => [],
               "meta" => %{"current_page" => 1, "total_page" => 1}
             }
    end
  end

  describe "show" do
    test "when id is eth_address", %{conn: conn, udt: udt} do
      conn =
        get(
          conn,
          ~p"/api/udts/#{to_string(udt.contract_address_hash)}"
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "attributes" => %{
                   "decimal" => udt.decimal,
                   "description" => udt.description,
                   "eth_address" => to_string(udt.contract_address_hash),
                   "holder_count" => 0,
                   "icon" => udt.icon,
                   "id" => udt.id,
                   "name" => udt.name,
                   "official_site" => udt.official_site,
                   "supply" => udt.supply |> Decimal.to_string(),
                   "symbol" => udt.symbol,
                   "transfer_count" => 0,
                   "type" => to_string(udt.type)
                 },
                 "id" => to_string(udt.id),
                 "relationships" => %{},
                 "type" => "udt"
               },
               "included" => []
             }
    end

    test "when id is integer", %{conn: conn, udt: udt} do
      conn =
        get(
          conn,
          ~p"/api/udts/#{udt.id}"
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "attributes" => %{
                   "decimal" => udt.decimal,
                   "description" => udt.description,
                   "eth_address" => to_string(udt.contract_address_hash),
                   "holder_count" => 0,
                   "icon" => udt.icon,
                   "id" => udt.id,
                   "name" => udt.name,
                   "official_site" => udt.official_site,
                   "supply" => udt.supply |> Decimal.to_string(),
                   "symbol" => udt.symbol,
                   "transfer_count" => 0,
                   "type" => to_string(udt.type)
                 },
                 "id" => to_string(udt.id),
                 "relationships" => %{},
                 "type" => "udt"
               },
               "included" => []
             }
    end
  end
end
