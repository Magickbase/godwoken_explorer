defmodule GodwokenExplorer.LogView do
  use JSONAPI.View, type: "log"

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Account, Log, Repo, SmartContract, Transaction}

  def fields do
    [
      :data,
      :address_hash,
      :block_number,
      :transaction_hash,
      :first_topic,
      :second_topic,
      :third_topic,
      :fourth_topic,
      :abi
    ]
  end

  def id(%{index: index}), do: index

  def list_by_tx_hash(transaction_hash, page, page_size) do
    from(
      l in Log,
      left_join: a in Account,
      on: a.short_address == l.address_hash,
      left_join: s in SmartContract,
      on: s.account_id == a.id,
      where: l.transaction_hash == ^transaction_hash,
      select: %{
        data: l.data,
        index: l.index,
        address_hash: l.address_hash,
        first_topic: l.first_topic,
        second_topic: l.second_topic,
        third_topic: l.third_topic,
        fourth_topic: l.fourth_topic,
        abi: s.abi
      },
      order_by: [desc: :block_number, desc: :index]
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def list_by_address_hash(address_hash, page, page_size) do
    from(
      l in Log,
      left_join: a in Account,
      on: a.short_address == l.address_hash,
      left_join: s in SmartContract,
      on: s.account_id == a.id,
      join: t in Transaction,
      on: t.hash == l.transaction_hash,
      where: l.address_hash == ^address_hash,
      select: %{
        data: l.data,
        index: l.index,
        transaction_hash: l.transaction_hash,
        address_hash: l.address_hash,
        block_number: t.block_number,
        first_topic: l.first_topic,
        second_topic: l.second_topic,
        third_topic: l.third_topic,
        fourth_topic: l.fourth_topic,
        abi: s.abi
      },
      order_by: [desc: :block_number, desc: :index],
      limit: 25
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
