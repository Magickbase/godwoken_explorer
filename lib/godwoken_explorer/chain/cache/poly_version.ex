defmodule GodwokenExplorer.Chain.Cache.PolyVersion do
  @moduledoc """
  Cache for block count.
  """

  require Logger

  use GodwokenExplorer.Chain.MapCache,
    name: :poly_version,
    key: :version

  defp handle_fallback(:version) do
    case GodwokenRPC.fetch_poly_version() do
      {:ok, response} ->
        {:update, response["versions"]}

      {:error, reason} ->
        Logger.debug([
          "Coudn't fetch poly_version, reason: #{inspect(reason)}"
        ])

        {:return, nil}
    end
  end

  defp handle_fallback(_key), do: {:return, nil}
end
