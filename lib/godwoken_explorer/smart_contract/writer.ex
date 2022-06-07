defmodule GodwokenExplorer.SmartContract.Writer do
  @moduledoc """
  Generates smart-contract transactions
  """

  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.SmartContract.Helper

  @spec write_functions(Hash.t()) :: [%{}]
  def write_functions(contract_address_hash) do
    abi =
      contract_address_hash
      |> Chain.address_hash_to_smart_contract()
      |> Map.get(:abi)

    case abi do
      nil ->
        []

      _ ->
        abi
        |> filter_write_functions()
    end
  end

  def write_function?(function) do
    !Helper.error?(function) && !Helper.event?(function) && !Helper.constructor?(function) &&
      (Helper.payable?(function) || Helper.nonpayable?(function))
  end

  defp filter_write_functions(abi) do
    abi
    |> Enum.filter(&write_function?(&1))
  end
end
