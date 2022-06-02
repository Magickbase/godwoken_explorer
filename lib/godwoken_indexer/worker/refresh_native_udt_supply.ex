defmodule GodwokenIndexer.Worker.RefreshNativeUDTSupply do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(u in UDT, preload: [:account], where: u.type == :native)
    |> Repo.all()
    |> Enum.each(fn u ->
      supply = UDT.eth_call_total_supply(u.account.short_address)

      UDT.changeset(u, %{
        supply: supply
      })
      |> Repo.update()
    end)

    :ok
  end
end
