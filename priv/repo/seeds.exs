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
alias GodwokenExplorer.UDT
%UDT{id: 1, decimal: 8, name: "nervos", symbol: "CKB", typescript_hash: "0x0000000000000000000000000000000000000000000000000000000000000000"} |> Repo.insert!()
