defmodule GodwokenExplorerWeb.API.SearchControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  describe "index" do
    test "when keyword is bigger than integer", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/search?keyword=932955726849138728"
        )

      assert json_response(conn, 404) ==
               %{"errors" => %{"detail" => "", "status" => "404", "title" => "not found"}}
    end

    test "search polyjuice contract", %{conn: conn} do
      account = insert(:polyjuice_contract_account)

      conn =
        get(
          conn,
          ~p"/api/search?keyword=#{to_string(account.eth_address)}"
        )

      assert json_response(conn, 200) == %{
               "id" => to_string(account.eth_address),
               "type" => "account"
             }
    end

    test "search not exist address will automatically insert", %{conn: conn} do
      address = "0xbFbE23681D99A158f632e64A31288946770c7A9e"

      conn =
        get(
          conn,
          ~p"/api/search?keyword=#{address}"
        )

      assert json_response(conn, 200) == %{
               "id" => address |> String.downcase(),
               "type" => "address"
             }
    end

    test "search block", %{conn: conn} do
      block = insert(:block)

      conn =
        get(
          conn,
          ~p"/api/search?keyword=#{to_string(block.hash)}"
        )

      assert json_response(conn, 200) == %{
               "id" => block.number,
               "type" => "block"
             }
    end

    test "search transaction", %{conn: conn} do
      transaction = insert(:transaction)

      conn =
        get(
          conn,
          ~p"/api/search?keyword=#{to_string(transaction.eth_hash)}"
        )

      assert json_response(conn, 200) == %{
               "id" => to_string(transaction.eth_hash),
               "type" => "transaction"
             }
    end

    test "search udt", %{conn: conn} do
      udt = insert(:native_udt)

      conn =
        get(
          conn,
          ~p"/api/search?keyword=#{udt.name}"
        )

      assert json_response(conn, 200) == %{
               "id" => udt.id,
               "type" => "udt"
             }
    end
  end
end
