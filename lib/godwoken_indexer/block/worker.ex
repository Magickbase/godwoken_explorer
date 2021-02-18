defmodule GodwokenIndexer.Block.Worker do
  use GenServer

  alias GodwokenRPC.{TipNumber, Block}
  alias GodwokenExplorer.Block, as: BlockRepo
  alias GodwokenExplorer.Chain.Events.Publisher

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # Do the desired work here
    fetch_and_import()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp fetch_and_import do
    with {:ok, max_number} <- fetch_max_number() do
      next_number = BlockRepo.get_next_number()
      if next_number < max_number do
        Enum.each(next_number..next_number, fn number ->
          case Block.request(number) do
            {:ok, %{body: body, status_code: 200}} ->
              response = Jason.decode!(body)["result"]
              {:ok, data} = BlockRepo.create_block(%{
                "hash" => response["hash"],
                "parent_hash" => response["raw"]["parent_block_hash"],
                "number" => response["raw"]["number"] |> String.slice(2..-1) |> String.to_integer(16),
                "timestamp" => response["raw"]["timestamp"]|> String.slice(2..-1) |> String.to_integer(16) |> timestamp_to_datetime,
                "miner_id" => response["raw"]["block_producer_id"],
                "transaction_count" => response["transactions"] |> Enum.count
              })
              Publisher.broadcast([{:blocks, data.hash}], :realtime)
            _ ->
             {:error, "Fetch block failed"}
          end
        end)
      end
    end
  end

  defp fetch_max_number do
    case TipNumber.request do
      {:ok, %{body: body, status_code: 200}} ->
        max_number =
          body
          |> Jason.decode!
          |> Map.fetch!("result")
          |> String.slice(2..-1)
          |> String.to_integer(16)

        {:ok, max_number}
      _ ->
        {:error, "Fetch max number failed"}
    end
  end

  defp timestamp_to_datetime(timestamp) do
      timestamp
      |> DateTime.from_unix!()
  end

  defp schedule_work do
    Process.send_after(self(), :work, 5 * 1000)
  end
end
