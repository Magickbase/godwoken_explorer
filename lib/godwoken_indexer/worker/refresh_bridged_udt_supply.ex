defmodule GodwokenIndexer.Worker.RefreshBridgedUDTSupply do
  @moduledoc """
  Calculated bridge udt's supply when deposit and withdrawal request.
  """
  use Oban.Worker, queue: :default, unique: [period: 60]

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias Ecto.Multi

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"udt_id" => udt_id}}) do
    with %UDT{bridge_account_id: bridge_account_id} = u when not is_nil(bridge_account_id) <-
           Repo.get(UDT, udt_id),
         %UDT{contract_address_hash: contract_address_hash} = udt
         when not is_nil(contract_address_hash) <- Repo.get(UDT, bridge_account_id) do
      %{supply: supply} =
        contract_address_hash |> to_string() |> MetadataRetriever.get_total_supply_of()

      Multi.new()
      |> Multi.run(
        :bridged_udt,
        fn repo, _ ->
          {:ok, u |> UDT.changeset(%{supply: supply}) |> repo.update()}
        end
      )
      |> Multi.run(:native_udt, fn repo, _ ->
        {:ok, udt |> UDT.changeset(%{supply: supply}) |> repo.update()}
      end)
      |> Repo.transaction()
    end

    :ok
  end
end
