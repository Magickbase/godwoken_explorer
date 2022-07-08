defmodule GodwokenExplorer.Chain.Exporter.HolderCsv do
  alias NimbleCSV.RFC4180

  def export(results) do
    results
    |> to_csv_format()
    |> dump_to_stream()
  end

  defp dump_to_stream(holders) do
    holders
    |> RFC4180.dump_to_stream()
  end

  defp to_csv_format(holders) do
    row_names = [
      "Address",
      "Balance",
      "Percentage",
      "Transaction Count"
    ]

    holder_lists =
      holders
      |> Stream.map(fn holder ->
        [
          holder[:eth_address],
          holder[:balance],
          holder[:percentage],
          holder[:tx_count]
        ]
      end)

    Stream.concat([row_names], holder_lists)
  end
end
