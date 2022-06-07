defmodule GodwokenExplorer.SmartContract.Solidity.Publisher do
  @moduledoc """
  Module responsible to control the contract verification.
  """

  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.SmartContract.CompilerVersion
  alias GodwokenExplorer.SmartContract.Solidity.Verifier

  @doc """
  Evaluates smart contract authenticity and saves its details.

  ## Examples
      GodwokenExplorer.SmartContract.Solidity.Publisher.publish(
        "0x0f95fa9bc0383e699325f2658d04e8d96d87b90c",
        %{
          "compiler_version" => "0.4.24",
          "contract_source_code" => "pragma solidity ^0.4.24; contract SimpleStorage { uint storedData; function set(uint x) public { storedData = x; } function get() public constant returns (uint) { return storedData; } }",
          "name" => "SimpleStorage",
          "optimization" => false
        }
      )
      #=> {:ok, %GodwokenExplorer.Chain.SmartContract{}}

  """
  def publish(address_hash, params, external_libraries \\ %{}) do
    params_with_external_libaries = add_external_libraries(params, external_libraries)

    case Verifier.evaluate_authenticity(address_hash, params_with_external_libaries) do
      {:ok, %{abi: abi, constructor_arguments: constructor_arguments}} ->
        params_with_constructor_arguments =
          Map.put(params_with_external_libaries, "constructor_arguments", constructor_arguments)

        publish_smart_contract(address_hash, params_with_constructor_arguments, abi)

      {:ok, %{abi: abi}} ->
        publish_smart_contract(address_hash, params_with_external_libaries, abi)

      {:error, error} ->
        {:error, error}

      {:error, error, _error_message} ->
        {:error, error}
    end
  end

  def publish_with_standard_json_input(%{"address_hash" => address_hash} = params, json_input) do
    case Verifier.evaluate_authenticity_via_standard_json_input(address_hash, params, json_input) do
      {:ok, %{abi: abi, constructor_arguments: constructor_arguments}, additional_params} ->
        params_with_constructor_arguments =
          params
          |> Map.put("constructor_arguments", constructor_arguments)
          |> Map.merge(additional_params)

        publish_smart_contract(address_hash, params_with_constructor_arguments, abi)

      {:ok, %{abi: abi}, additional_params} ->
        merged_params = Map.merge(params, additional_params)
        publish_smart_contract(address_hash, merged_params, abi)

      {:error, error} ->
        {:error, error}

      {:error, error, _error_message} ->
        {:error, error}

      _ ->
        {:error, "Failed to verify"}
    end
  end

  def publish_smart_contract(address_hash, params, abi) do
    attrs = address_hash |> attributes(params, abi)

    create_or_update_smart_contract(address_hash, attrs)
  end

  def publish_smart_contract(address_hash, params, abi, file_path) do
    attrs = address_hash |> attributes(params, file_path, abi)

    create_or_update_smart_contract(address_hash, attrs)
  end

  defp create_or_update_smart_contract(address_hash, attrs) do
    if Chain.smart_contract_verified?(address_hash) do
      Chain.update_smart_contract(attrs)
    else
      Chain.create_smart_contract(attrs)
    end
  end

  defp attributes(address_hash, params, file_path, abi) do
    Map.put(attributes(address_hash, params, abi), :file_path, file_path)
  end

  defp attributes(address_hash, params, abi \\ %{}) do
    constructor_arguments = params["constructor_arguments"]

    clean_constructor_arguments =
      if constructor_arguments != nil && constructor_arguments != "" do
        constructor_arguments
      else
        nil
      end

    compiler_version =
      CompilerVersion.get_strict_compiler_version(:solc, params["compiler_version"])

    %{
      address_hash: address_hash,
      name: params["name"],
      compiler_version: compiler_version,
      contract_source_code: params["contract_source_code"],
      constructor_arguments: clean_constructor_arguments,
      abi: abi,
      account_id: params["account_id"],
      deployment_tx_hash: params["deployment_tx_hash"]
    }
  end

  defp add_external_libraries(params, external_libraries) do
    clean_external_libraries =
      Enum.reduce(1..10, %{}, fn number, acc ->
        address_key = "library#{number}_address"
        name_key = "library#{number}_name"

        address = external_libraries[address_key]
        name = external_libraries[name_key]

        if is_nil(address) || address == "" || is_nil(name) || name == "" do
          acc
        else
          Map.put(acc, name, address)
        end
      end)

    Map.put(params, "external_libraries", clean_external_libraries)
  end
end
