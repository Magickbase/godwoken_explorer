defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, Transaction, Block, Polyjuice, PolyjuiceCreator}

  import Ecto.Query

  ## TODO: wait for optimize
  def latest_10_transactions(_parent, _args, _resolution) do
    return =
      from(t in Transaction,
        limit: 10,
        order_by: [desc: t.inserted_at]
      )
      |> Repo.all()

    {:ok, return}
  end

  def transaction(_parent, %{input: input} = _args, _resolution) do
    transaction_hash = Map.get(input, :transaction_hash)
    Repo.get(Transaction, transaction_hash)
    {:ok, Repo.get(Transaction, transaction_hash)}
  end

  # TODO: wait for optimize
  def transactions(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)

    account =
      from(
        a in Account,
        where:
          a.eth_address == ^address or a.script_hash == ^address or
            a.short_address == ^address
      )
      |> Repo.one()

    query_condition =
      case account do
        %Account{type: :user} ->
          from t in Transaction,
            where: t.from_account_id == ^account.id,
            limit: 100,
            order_by: [desc: t.inserted_at]

        %Account{type: type}
        when type in [:meta_contract, :udt, :polyjuice_root, :polyjuice_contract] ->
          from t in Transaction,
            where: t.to_account_id == ^account.id,
            limit: 100,
            order_by: [desc: t.inserted_at]
      end

    {:ok, Repo.all(query_condition)}
  end

  def polyjuice(%Transaction{hash: hash}, _args, _resolution) do
    return =
      Repo.one(
        from p in Polyjuice,
          where: p.tx_hash == ^hash
      )

    {:ok, return}
  end

  def polyjuice_creator(%Transaction{hash: hash}, _args, _resolution) do
    return =
      Repo.one(
        from pc in PolyjuiceCreator,
          where: pc.tx_hash == ^hash
      )

    {:ok, return}
  end

  def block(%Transaction{block_hash: block_hash}, _args, _resolution) do
    {:ok, Repo.get(Block, block_hash)}
  end

  def from_account(%Transaction{from_account_id: from_account_id}, _args, _resolution) do
    {:ok, Repo.get(Account, from_account_id)}
  end

  def to_account(%Transaction{to_account_id: to_account_id}, _args, _resolution) do
    {:ok, Repo.get(Account, to_account_id)}
  end
end
