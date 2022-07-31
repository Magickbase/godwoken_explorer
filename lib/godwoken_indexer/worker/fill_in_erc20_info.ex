defmodule GodwokenIndexer.Worker.FillInERC20Info do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenExplorer.Chain

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(u in UDT,
      where: u.type == :native and u.eth_type == :erc20 and is_nil(u.name),
      limit: 50
    )
    |> Repo.all()
    |> Enum.each(fn udt ->
      result = MetadataRetriever.get_functions_of(udt.contract_address_hash)
      udt_to_update = udt |> Repo.preload(:account)

      Chain.update_udt(
        %{
          udt_to_update
          | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        },
        result
      )
    end)

    :ok
  end
end
