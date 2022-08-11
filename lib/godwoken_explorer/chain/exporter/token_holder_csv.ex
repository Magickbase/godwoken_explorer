defmodule GodwokenExplorer.Chain.Exporter.TokenHolderCsv do
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
      "Balance"
    ]

    holder_lists =
      holders
      |> Stream.map(fn holder ->
        [
          holder[:address_hash],
          holder[:value]
        ]
      end)

    Stream.concat([row_names], holder_lists)
  end
end
