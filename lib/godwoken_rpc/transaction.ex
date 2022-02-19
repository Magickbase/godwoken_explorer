defmodule GodwokenRPC.Transaction do
  import GodwokenRPC.Util, only: [hex_to_number: 1, parse_le_number: 1, transform_hash_type: 1, parse_polyjuice_args: 1]
  import Godwoken.MoleculeParser, only: [parse_meta_contract_args: 1, parse_sudt_transfer_args: 1]

  alias GodwokenExplorer.{Account, Polyjuice, Repo, AccountUDT}

  def elixir_to_params(%{
        "block_hash" => block_hash,
        "block_number" => block_number,
        "raw" => %{
          "from_id" => from_account_id,
          "to_id" => to_account_id,
          "nonce" => nonce,
          "args" => "0x" <> args
        },
        "hash" => hash
      })
      when to_account_id == "0x0" do
    {{code_hash, hash_type, script_args}, {fee_sudt_id, fee_amount_hex_string}} =
      parse_meta_contract_args(args)

    fee_amount = fee_amount_hex_string |> parse_le_number()
    from_account_id = hex_to_number(from_account_id)

    %{
      type: :polyjuice_creator,
      hash: hash,
      block_hash: block_hash,
      block_number: block_number,
      nonce: hex_to_number(nonce),
      args: "0x" <> args,
      from_account_id: from_account_id,
      to_account_id: hex_to_number(to_account_id),
      code_hash: "0x" <> code_hash,
      hash_type: transform_hash_type(hash_type),
      fee_udt_id: fee_sudt_id,
      fee_amount: fee_amount,
      script_args: script_args,
      account_ids: [from_account_id]
    }
  end

  def elixir_to_params(%{
        "block_hash" => block_hash,
        "block_number" => block_number,
        "raw" => %{
          "from_id" => from_account_id,
          "to_id" => to_id,
          "nonce" => nonce,
          "args" => "0x" <> args
        },
        "hash" => hash
      }) do
    if String.starts_with?(args, "ffffff504f4c59") do
      [is_create, gas_limit, gas_price, value, input_size, input] = parse_polyjuice_args(args)

      from_account_id = hex_to_number(from_account_id)
      to_account_id = hex_to_number(to_id)
      {:ok, %{"gasUsed" => gas_used, "status" => hex_status}} = GodwokenRPC.fetch_receipt(hash)
      status = if hex_status == "0x0", do: :failed, else: :succeed
      {short_address, transfer_count} =
        Polyjuice.decode_transfer_args(to_account_id, input, hash)

      eth_address =
        if short_address do
          # AccountUDT.update_erc20_balance!(from_account_id, to_account_id)

          case Account |> Repo.get_by(short_address: short_address) do
            nil ->
              nil

            %Account{id: _id, eth_address: eth_address} ->
              # AccountUDT.update_erc20_balance!(id, to_account_id)
              eth_address
          end
        end

      %{
        type: :polyjuice,
        hash: hash,
        block_hash: block_hash,
        block_number: block_number,
        nonce: hex_to_number(nonce),
        args: "0x" <> args,
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        is_create: is_create,
        gas_limit: gas_limit,
        gas_price: gas_price,
        gas_used: hex_to_number(gas_used),
        status: status,
        value: value,
        input_size: input_size,
        input: input,
        receive_address: short_address,
        receive_eth_address: eth_address,
        transfer_count: transfer_count,
        account_ids: [from_account_id, to_account_id]
      }
    else
      {short_address, amount, fee} = parse_sudt_transfer_args(args)
      {:ok, to_account_id} = Account.find_by_short_address("0x" <> short_address)
      from_account_id = hex_to_number(from_account_id)

      %{
        type: :sudt,
        hash: hash,
        block_hash: block_hash,
        block_number: block_number,
        nonce: hex_to_number(nonce),
        args: "0x" <> args,
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        udt_id: hex_to_number(to_id),
        amount: amount,
        fee: fee,
        account_ids: [from_account_id, to_account_id]
      }
    end
  end
end
