defmodule GodwokenIndexer.Worker.RefreshNativeUDTSupply do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(u in UDT, where: u.type == :native and u.eth_type == :erc20)
    |> Repo.all()
    |> Enum.each(fn u ->
      decimal =
        if is_nil(u.decimal) do
          u.contract_address_hash |> to_string() |> UDT.eth_call_decimal()
        else
          u.decimal
        end

      name =
        if is_nil(u.name) do
          u.contract_address_hash |> to_string() |> UDT.eth_call_name()
        else
          u.name
        end

      symbol =
        if is_nil(u.symbol) do
          u.contract_address_hash |> to_string() |> UDT.eth_call_symbol()
        else
          u.symbol
        end

      supply = u.contract_address_hash |> to_string() |> UDT.eth_call_total_supply()

      UDT.changeset(u, %{
        supply: supply,
        decimal: decimal,
        name: name,
        symbol: symbol
      })
      |> Repo.update()
    end)

    :ok
  end
end
