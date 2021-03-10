# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GodwokenExplorer.Repo.insert(%GodwokenExplorer.SomeSchema{})
#
# We recommend using the bang functions (`insert`, `update!`
# and so on) as they will fail if something goes wrong.

alias GodwokenExplorer.Repo
alias GodwokenExplorer.{UDT, AccountUDT}

%UDT{
  id: 1,
  decimal: 8,
  name: "nervos",
  symbol: "CKB",
  supply: 24_201_160_775,
  script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000"
}
|> Repo.insert!()

%UDT{
  id: 3,
  decimal: 6,
  name: "TestName",
  symbol: "TN",
  supply: 1_000_000_000,
  type_script: %{
    name: "sudt",
    code_hash: "0x71fa23eb5154750ff2c7de053674935b4844e1e0744f35e005b0658e569eeb66",
    hash_type: "type",
    args: "0x979d485c2adc3432c679230dc2a46ab3f900e85be0dd5eecf17adfcc5d78df5a"
  },
  script_hash: "0x44cfdc675dff47358c915d4b226df72784ba6b3529041279f2374cd8f2a7008e"
}
|> Repo.insert!()

%AccountUDT{account_id: 2, udt_id: 3, balance: 1_234_567_890_123_456_789}
|> Repo.insert!()

%AccountUDT{account_id: 2, udt_id: 1, balance: 2_345_678_919_293_456}
|> Repo.insert!()
