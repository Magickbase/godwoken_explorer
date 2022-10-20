defmodule GodwokenExplorer.Chain.Exporter.TransactionTransferCsv do
  @moduledoc """
  Export a transaction's transfer list
  """
  alias GodwokenExplorer.TokenTransfer
  alias NimbleCSV.RFC4180

  def export(tx_hash) do
    results = TokenTransfer.list(%{tx_hash: tx_hash}, nil)

    results
    |> to_csv_format()
    |> dump_to_stream()
  end

  defp dump_to_stream(token_transfers) do
    token_transfers
    |> RFC4180.dump_to_stream()
  end

  defp to_csv_format(token_transfers) do
    row_names = [
      "FromAddress",
      "ToAddress",
      "Value"
    ]

    token_transfer_lists =
      token_transfers
      |> Stream.map(fn token_transfer ->
        [
          token_transfer[:from],
          token_transfer[:to],
          token_transfer[:transfer_value]
        ]
      end)

    Stream.concat([row_names], token_transfer_lists)
  end
end
