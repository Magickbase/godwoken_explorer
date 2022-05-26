defmodule GodwokenExplorerWeb.API.BlockControllerTest do
  use GodwokenExplorer, :schema
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Factory

  setup do
    Repo.insert(Factory.meta_contract_factory())
    block = Repo.insert!(Factory.block_factory())

    block
    |> Ecto.Changeset.change(%{
      inserted_at: NaiveDateTime.truncate(~U[2021-10-31 05:39:38.000000Z], :second)
    })
    |> Repo.update()

    :ok
  end

  describe "index" do
    test "return all block", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.block_path(
            conn,
            :index
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "finalize_state" => "finalized",
                       "gas_limit" => "12500000",
                       "gas_used" => "0",
                       "hash" =>
                         "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                       "miner_hash" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                       "number" => 14,
                       "timestamp" => 1_635_658_778,
                       "tx_count" => 1
                     },
                     "id" => 14,
                     "relationships" => %{},
                     "type" => "block"
                   }
                 ],
                 "included" => [],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end
  end

  describe "show" do
    test "when block exist", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.block_path(
            conn,
            :show,
            "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "hash" => "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                 "number" => 14,
                 "l1_block" => 2_345_241,
                 "l1_tx_hash" =>
                   "0xae12080b62ec17acc092b341a6ca17da0708e7a6d77e8033c785ea48cdbdbeef",
                 "finalize_state" => "finalized",
                 "tx_count" => 1,
                 "miner_hash" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                 "timestamp" => 1_635_658_778,
                 "gas_limit" => "12500000",
                 "gas_used" => "0",
                 "size" => 156,
                 "parent_hash" =>
                   "0xa04ecc2bb1bc634848535b60b3223c1cd5278aa93abb2c138687da8ffa9ffd48",
                 "logs_bloom" =>
                   "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
               }
    end
  end
end
