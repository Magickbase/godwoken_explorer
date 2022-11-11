defmodule GodwokenIndexer.Worker.UpdateUDTInfo do
  @moduledoc """
  Fetch udt's meta and update.
  """
  use Oban.Worker, queue: :default, unique: [period: 300, states: Oban.Job.states()]

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenExplorer.Chain

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"address_hash" => address_hash}}) do
    udt_to_update =
      UDT |> Repo.get_by(contract_address_hash: address_hash) |> Repo.preload(:account)

    infos = address_hash |> to_string() |> MetadataRetriever.get_functions_of()

    {:ok, _} =
      Chain.update_udt(
        %{
          udt_to_update
          | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        },
        infos
      )

    :ok
  end
end
