defmodule GodwokenExplorer.AccountTest do
  use GodwokenExplorer.DataCase

  import Mock

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
end
