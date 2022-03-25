defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  # TODO: show udt
  def udt(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show udt
  def get_udt_by_contract_address(
        _parent,
        %{input: %{contract_address: contract_address}},
        _resolution
      ) do
    account = Account.search(contract_address)

    udt =
      from(u in UDT, where: u.id == ^account.id or u.bridge_account_id == ^account.id)
      |> Repo.one()

    {:ok, udt}
  end

  # TODO: show udts
  def udts(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show account
  def account(%UDT{} = _parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show bridge_account
  def bridge_account(%UDT{} = _parent, _args, _resolution) do
    {:ok, nil}
  end
end
