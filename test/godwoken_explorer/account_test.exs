defmodule GodwokenExplorer.AccountTest do
  use GodwokenExplorer.DataCase

  import Mock
  import Hammox

  alias GodwokenExplorer.{Account, Repo}

  test "batch_import_accounts_with_script_hashes" do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_account_ids: fn _ ->
           {:ok,
            %GodwokenRPC.Account.FetchedAccountIDs{
              errors: [],
              params_list: [
                %{
                  script_hash:
                    "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9",
                  script: nil,
                  id: 48250
                }
              ]
            }}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_scripts: fn _ ->
           {:ok,
            %{
              errors: [],
              params_list: [
                %{
                  script_hash:
                    "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9",
                  script: %{
                    "args" =>
                      "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd80400000017f01ec05a4a6a43857e3bb8d8ddd68e8d1d185f",
                    "code_hash" =>
                      "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                    "hash_type" => "type"
                  },
                  id: 48250
                }
              ]
            }}
         end
       ]}
    ]) do
      Account.batch_import_accounts_with_script_hashes([
        "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9"
      ])

      account = Account |> Repo.one()
      assert Account |> Repo.aggregate(:count) == 1
      assert account.id == 48250

      assert account.script_hash |> to_string() ==
               "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9"
    end
  end

  describe "find_or_create_contract_by_eth_address/1" do
    test "when account not exist in chain" do
      MockGodwokenRPC
      |> expect(:fetch_account_id, fn _script_hash ->
        {:error, :account_slow}
      end)

      assert Account.find_or_create_contract_by_eth_address(
               "0x17f01ec05a4a6a43857e3bb8d8ddd68e8d1d185f"
             ) == {:error, nil}
    end

    test "when account exist in chain" do
      MockGodwokenRPC
      |> expect(:fetch_account_id, fn _script_hash ->
        {:ok, 48250}
      end)
      |> expect(:fetch_nonce, fn id ->
        assert id == 48250

        10
      end)
      |> expect(:fetch_script, fn script_hash ->
        assert script_hash == "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9"

        {:ok,
         %{
           "args" =>
             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd80400000017f01ec05a4a6a43857e3bb8d8ddd68e8d1d185f",
           "code_hash" => "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
           "hash_type" => "type"
         }}
      end)
      |> expect(:fetch_script_hash, fn params ->
        assert params == %{account_id: 48250}

        {:ok, "0x74db559cbb4928e1c2dfb6ab30623bb338a53904f47458c02a07be01c84b1af9"}
      end)

      assert Account.find_or_create_contract_by_eth_address(
               "0x17f01ec05a4a6a43857e3bb8d8ddd68e8d1d185f"
             ) == {:ok, Repo.get(Account, 48250)}
    end
  end

  test "handle eoa to contract" do
    eoa =
      insert(:user, registry_address: "0x0200000014000000c3dc7b0ea12a45830e89326dde9f2dadce0dbc5d")

    contract =
      insert(:polyjuice_contract_account,
        eth_address: eoa.eth_address,
        registry_address: "0x0200000014000000c3dc7b0ea12a45830e89326dde9f2dadce0dbc5d"
      )

    Account.handle_eoa_to_contract(eoa.eth_address)
    assert eoa |> Repo.reload!() |> Map.get(:eth_address) == nil
    assert eoa |> Repo.reload!() |> Map.get(:registry_address) == nil
    assert contract |> Repo.reload!() |> Map.get(:eth_address) != nil
    assert contract |> Repo.reload!() |> Map.get(:registry_address) != nil
  end
end
