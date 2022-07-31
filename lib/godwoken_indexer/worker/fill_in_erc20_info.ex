defmodule GodwokenIndexer.Worker.FillInERC20Info do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(u in UDT,
      where: u.type == :native and u.eth_type == :erc20 and is_nil(u.name),
      limit: 100
    )
    |> Repo.all()
    |> Enum.each(fn u ->
      decimal = u.contract_address_hash |> to_string() |> UDT.eth_call_decimal()
      name = u.contract_address_hash |> to_string() |> UDT.eth_call_name()
      symbol = u.contract_address_hash |> to_string() |> UDT.eth_call_symbol()

      UDT.changeset(u, %{
        decimal: decimal,
        name: name,
        symbol: symbol
      })
      |> Repo.update()
    end)

    :ok
  end
end
