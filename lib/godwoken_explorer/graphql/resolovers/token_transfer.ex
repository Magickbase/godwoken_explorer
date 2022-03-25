defmodule GodwokenExplorer.Graphql.Resolvers.TokenTransfer do
  alias GodwokenExplorer.{TokenTransfer, Polyjuice, Account, UDT, Block, Transaction}

  alias GodwokenExplorer.Repo

  import Ecto.Query

  def token_transfer(_parent, %{input: %{transaction_hash: transaction_hash}}, _resolution) do
    return = Repo.get(TokenTransfer, transaction_hash)
    {:ok, return}
  end

  def token_transfers(_parent, %{input: input}, _resolution) do
    {:ok, get_token_transfers(input)}
  end

  def polyjuice(%TokenTransfer{transaction_hash: transaction_hash}, _args, _resolution) do
    return = Repo.one(from p in Polyjuice, where: p.tx_hash == ^transaction_hash)
    {:ok, return}
  end

  def block(%TokenTransfer{block_hash: block_hash}, _args, _resolution) do
    return = Repo.get(Block, block_hash)
    {:ok, return}
  end

  def from_account(%TokenTransfer{from_address_hash: from_address_hash}, _args, _resolution) do
    return = from(a in Account, where: a.short_address == ^from_address_hash) |> Repo.one()
    {:ok, return}
  end

  def to_account(%TokenTransfer{to_address_hash: to_address_hash}, _args, _resolution) do
    return = from(a in Account, where: a.short_address == ^to_address_hash) |> Repo.one()
    {:ok, return}
  end

  def udt(
        %TokenTransfer{token_contract_address_hash: token_contract_address_hash},
        _args,
        _resolution
      ) do
    udt = UDT.get_by_contract_address(token_contract_address_hash)
    {:ok, udt}
  end

  def transaction(%TokenTransfer{transaction_hash: transaction_hash}, _args, _resolution) do
    return = Repo.one(from t in Transaction, where: t.hash == ^transaction_hash)
    {:ok, return}
  end

  defp get_token_transfers(input) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:from_address_hash, value} ->
            dynamic([tt], ^acc and tt.from_address_hash == ^value)

          {:to_address_hash, value} ->
            dynamic([tt], ^acc and tt.to_address_hash == ^value)

          {:token_contract_address_hash, value} ->
            dynamic([tt], ^acc and tt.token_contract_address_hash == ^value)

          {:start_block_number, value} ->
            dynamic([tt], ^acc and tt.block_number >= ^value)

          {:end_block_number, value} ->
            dynamic([tt], ^acc and tt.end_block_number <= ^value)

          _ ->
            acc
        end
      end)

    from(tt in TokenTransfer, where: ^conditions)
    |> limit(100)
    |> Repo.all()
  end
end
