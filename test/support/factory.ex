defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: GodwokenExplorer.Repo
  use GodwokenExplorer.AccountFactory
  use GodwokenExplorer.AccountUDTFactory
  use GodwokenExplorer.BlockFactory
  use GodwokenExplorer.TransactionFactory
  use GodwokenExplorer.UDTFactory

  alias GodwokenExplorer.Repo

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
