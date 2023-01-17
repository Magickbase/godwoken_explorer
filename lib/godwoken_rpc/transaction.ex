defmodule GodwokenRPC.Transaction do
  import GodwokenRPC.Util,
    only: [
      hex_to_number: 1,
      parse_le_number: 1,
      transform_hash_type: 1,
      parse_polyjuice_args: 1,
      parse_gas_less_data: 1
    ]

  import GodwokenExplorer.MoleculeParser,
    only: [parse_meta_contract_args: 1]

  require Logger

  @eth_addr_reg_id Application.compile_env(:godwoken_explorer, :eth_addr_reg_id)
  @gas_less_entrypoint_id Application.compile_env(:godwoken_explorer, :gas_less_entrypoint_id)

  def elixir_to_params(
        {%{
           "block_hash" => block_hash,
           "block_number" => block_number,
           "raw" => %{
             "from_id" => from_account_id,
             "to_id" => to_account_id,
             "nonce" => nonce,
             "args" => "0x" <> args
           },
           "hash" => hash
         }, index}
      )
      when to_account_id == "0x0" do
    {{code_hash, hash_type, script_args}, {registry_id, fee_amount_hex_string}} =
      parse_meta_contract_args(args)

    fee_amount = fee_amount_hex_string |> parse_le_number()
    from_account_id = hex_to_number(from_account_id)

    %{
      type: :polyjuice_creator,
      hash: hash,
      eth_hash: nil,
      block_hash: block_hash,
      block_number: block_number,
      index: index,
      nonce: hex_to_number(nonce),
      args: "0x" <> args,
      from_account_id: from_account_id,
      to_account_id: 0,
      code_hash: "0x" <> code_hash,
      hash_type: transform_hash_type(hash_type),
      fee_amount: fee_amount,
      fee_registry_id: registry_id,
      script_args: "0x" <> script_args,
      account_ids: [from_account_id]
    }
  end

  def elixir_to_params(
        {%{
           "block_hash" => block_hash,
           "block_number" => block_number,
           "raw" => %{
             "from_id" => from_account_id,
             "to_id" => to_id,
             "nonce" => nonce,
             "args" => "0x" <> args
           },
           "hash" => hash
         }, index}
      ) do
    from_account_id = hex_to_number(from_account_id)
    to_account_id = hex_to_number(to_id)

    cond do
      String.starts_with?(args, "ffffff504f4c59") ->
        [is_create, gas_limit, gas_price, value, input_size, input, native_transfer_address_hash] =
          parse_polyjuice_args(args)

        {call_contract, call_data, call_gas_limit, verification_gas_limit, max_fee_per_gas,
         max_priority_fee_per_gas,
         paymaster_and_data} =
          if to_account_id == @gas_less_entrypoint_id && gas_price == 0 &&
               String.starts_with?(input, "0xfb4350d8") do
            input |> String.slice(10..-1) |> parse_gas_less_data()
          else
            {nil, nil, nil, nil, nil, nil, nil}
          end

        %{
          type: :polyjuice,
          hash: hash,
          block_hash: block_hash,
          block_number: block_number,
          index: index,
          nonce: hex_to_number(nonce),
          args: "0x" <> args,
          from_account_id: from_account_id,
          to_account_id: to_account_id,
          is_create: is_create,
          gas_limit: gas_limit,
          gas_price: gas_price,
          value: value,
          input_size: input_size,
          input: input,
          native_transfer_address_hash: native_transfer_address_hash,
          call_contract: call_contract,
          call_data: call_data,
          call_gas_limit: call_gas_limit,
          verification_gas_limit: verification_gas_limit,
          max_fee_per_gas: max_fee_per_gas,
          max_priority_fee_per_gas: max_priority_fee_per_gas,
          paymaster_and_data: paymaster_and_data,
          account_ids: [from_account_id, to_account_id]
        }

      to_id == @eth_addr_reg_id ->
        # case parse_eth_address_registry_args(args) do
        #   {"EthToGw", eth_address, _} ->
        #     Logger.info("===========ETHToGw#{eth_address}")

        #   {"GwToEth", gw_script_hash, _} ->
        #     Logger.info("===========GwToEth#{gw_script_hash}")

        #   {"SetMapping", gw_script_hash, fee} ->
        #     Logger.info("===========SetMapping#{gw_script_hash}#{fee}")

        #   {"BatchSetMapping", gw_script_hashes, fee} ->
        #     Logger.info("===========BatchSetMapping#{gw_script_hashes}#{fee}")
        #     {hashes_count, str_hashes} = gw_script_hashes |> String.split_at(8)
        #     hashes = for <<x::binary-64 <- str_hashes>>, do: x
        # end

        %{
          type: :eth_address_registry,
          hash: hash,
          eth_hash: nil,
          block_hash: block_hash,
          block_number: block_number,
          index: index,
          nonce: hex_to_number(nonce),
          args: "0x" <> args,
          from_account_id: from_account_id,
          to_account_id: to_account_id,
          account_ids: [from_account_id, to_account_id]
        }
    end
  end
end
