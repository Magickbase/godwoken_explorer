defmodule GodwokenExplorer.SmartContract.Vyper.Publisher do
  @moduledoc """
  Module responsible to control Vyper contract verification.
  """

  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.SmartContract.CompilerVersion
  alias GodwokenExplorer.SmartContract.Vyper.Verifier

  def publish(address_hash, params) do
    case Verifier.evaluate_authenticity(address_hash, params) do
      {:ok, %{abi: abi}} ->
        publish_smart_contract(address_hash, params, abi)

      {:error, error} ->
        {:error, error}
    end
  end

  def publish_smart_contract(address_hash, params, abi) do
    attrs = address_hash |> attributes(params, abi)

    Chain.create_smart_contract(attrs)
  end

  defp attributes(address_hash, params, abi) do
    constructor_arguments = params["constructor_arguments"]

    clean_constructor_arguments =
      if constructor_arguments != nil && constructor_arguments != "" do
        constructor_arguments
      else
        nil
      end

    compiler_version =
      CompilerVersion.get_strict_compiler_version(:vyper, params["compiler_version"])

    %{
      address_hash: address_hash,
      name: "Vyper_contract",
      compiler_version: compiler_version,
      evm_version: nil,
      optimization_runs: nil,
      optimization: false,
      contract_source_code: params["contract_source_code"],
      constructor_arguments: clean_constructor_arguments,
      external_libraries: [],
      secondary_sources: [],
      abi: abi,
      verified_via_sourcify: false,
      partially_verified: false,
      is_vyper_contract: true
    }
  end
end
