defmodule GodwokenIndexer.Worker.TokenInstanceRetriesWorker do
  use Oban.Worker,
    queue: :token_instance,
    priority: 0,
    max_attempts: 3

  alias GodwokenExplorer.Repo
  alias GodowokenExplorer.TokenInstance

  alias GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata

  import Ecto.Query

  require Logger

  @impl Oban.Worker
  def perform(_) do
    do_perform()
  end

  @impl Oban.Worker
  def timeout(_job) do
    :infinity
  end

  def do_perform() do
    args = get_token_instance_with_nil_metadata()

    return =
      args
      |> ERC721ERC1155InstanceMetadata.pre_check()
      |> Enum.chunk_every(10)
      |> Enum.map(fn args ->
        Task.async_stream(
          args,
          fn arg ->
            ERC721ERC1155InstanceMetadata.do_perform(arg)
          end,
          timeout: :infinity
        )
        |> Enum.to_list()
      end)
      |> List.flatten()
      |> Enum.filter(fn {a, _} -> a != :ok end)

    {:ok, "#{inspect(return)}"}
  end

  def get_token_instance_with_nil_metadata do
    datetime = Timex.now() |> Timex.shift(seconds: -24 * 60 * 60)
    retry_error = ["timeout"]

    from(tt in TokenInstance,
      where:
        is_nil(tt.metadata) and tt.updated_at < ^datetime and
          tt.error in ^retry_error
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
