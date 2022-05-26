defmodule GodwokenIndexer.Worker.RefreshNativeUDTSupply do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2, where: 3, select: 3]

  alias GodwokenExplorer.{Repo, UDT, Account}

  @native_udt_addresses ["0x7fda8d4fb49a11ae6cf987c5e846b64954b32b59"]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    native_ids =
      Account
      |> where([a], a.eth_address in ^@native_udt_addresses)
      |> select([a], a.id)
      |> Repo.all()

    from(u in UDT, preload: [:account], where: u.bridge_account_id in ^native_ids)
    |> Repo.all()
    |> Enum.each(fn u ->
      supply = UDT.eth_call_total_supply(u.account.eth_address)

      UDT.changeset(u, %{
        supply: supply
      })
      |> Repo.update()
    end)

    :ok
  end
end
