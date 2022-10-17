defmodule GodwokenIndexer.Worker.TokenInstanceRetriesWorker do
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.Repo
  alias GodowokenExplorer.TokenInstance

  alias GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata

  import Ecto.Query

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_perform()
  end

  def do_perform() do
    args = get_token_instance_with_nil_metadata()
    ERC721ERC1155InstanceMetadata.new_job(args)
  end

  def get_token_instance_with_nil_metadata do
    from(tt in TokenInstance,
      where: is_nil(tt.metadata),
      limit: 200
    )
    |> Repo.all()
    |> Enum.map(fn tt ->
      %{
        "token_contract_address_hash" => tt.token_contract_address_hash |> to_string,
        "token_id" => tt.token_id |> Decimal.to_integer()
      }
    end)
  end
end
