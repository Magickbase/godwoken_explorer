defmodule GodwokenIndexer.Block.PendingTransactionWorker do
  use GenServer

  import GodwokenRPC.Util,
    only: [
      hex_to_number: 1,
      parse_polyjuice_args: 1,
      parse_le_number: 1,
      transform_hash_type: 1,
      import_timestamps: 0
    ]

  import Godwoken.MoleculeParser,
    only: [parse_meta_contract_args: 1]

  alias GodwokenExplorer.Chain.Import
  alias GodwokenExplorer.{Polyjuice, PolyjuiceCreator, Transaction}

  @default_worker_interval 40
  @eth_addr_reg_id Application.get_env(:godwoken_explorer, :eth_addr_reg_id)

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
  def handle_info(:fetch, state) do
    # Do the desired work here
    fetch_and_update()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  def fetch_and_update do
    {:ok, tx_hashes} = GodwokenRPC.fetch_pending_tx_hashes()

    tx_hashes_params = tx_hashes |> Enum.map(&%{gw_tx_hash: &1})

    {:ok, %{errors: [], params_list: params}} =
      GodwokenRPC.fetch_pending_transactions(tx_hashes_params)

    if params != [] do
      pending_transaction_attrs =
        params
        |> Enum.map(fn transaction ->
          tx = transaction["transaction"]
          tx["raw"] |> parse_raw() |> Map.put(:hash, tx["hash"])
        end)

      {polyjuice_params, polyjuice_creator_params, _eth_addr_reg_params} =
        group_transaction_params(pending_transaction_attrs)

      import_polyjuice(polyjuice_params)

      import_polyjuice_creator(polyjuice_creator_params)

      import_transaction(pending_transaction_attrs)
    end
  end

  defp import_polyjuice(polyjuice_with_receipts) do
    if polyjuice_with_receipts != [] do
      inserted_polyjuice_params = filter_polyjuice_columns(polyjuice_with_receipts)

      Import.insert_changes_list(inserted_polyjuice_params,
        for: Polyjuice,
        timestamps: import_timestamps(),
        on_conflict: :nothing
      )
    end
  end

  defp filter_polyjuice_columns(params) do
    params
    |> Enum.map(fn %{
                     is_create: is_create,
                     gas_limit: gas_limit,
                     gas_price: gas_price,
                     value: value,
                     input_size: input_size,
                     input: input,
                     hash: hash,
                     native_transfer_address_hash: native_transfer_address_hash
                   } ->
      %{
        is_create: is_create,
        gas_limit: gas_limit,
        gas_price: gas_price,
        value: value,
        input_size: input_size,
        input: input,
        tx_hash: hash,
        native_transfer_address_hash: native_transfer_address_hash
      }
    end)
  end

  defp import_polyjuice_creator(polyjuice_creator_params) do
    if polyjuice_creator_params != [] do
      inserted_polyjuice_creator_params =
        filter_polyjuice_creator_columns(polyjuice_creator_params)

      Import.insert_changes_list(inserted_polyjuice_creator_params,
        for: PolyjuiceCreator,
        timestamps: import_timestamps(),
        on_conflict: :nothing
      )
    end
  end

  defp filter_polyjuice_creator_columns(params) do
    params
    |> Enum.map(fn %{
                     code_hash: code_hash,
                     hash_type: hash_type,
                     script_args: script_args,
                     fee_amount: fee_amount,
                     fee_registry_id: fee_registry_id,
                     hash: hash
                   } ->
      %{
        code_hash: code_hash,
        hash_type: hash_type,
        script_args: script_args,
        fee_amount: fee_amount,
        fee_registry_id: fee_registry_id,
        tx_hash: hash
      }
    end)
  end

  defp import_transaction(transaction_params) do
    inserted_transaction_params = filter_transaction_columns(transaction_params)

    Import.insert_changes_list(inserted_transaction_params,
      for: Transaction,
      timestamps: import_timestamps(),
      on_conflict: :nothing
    )
  end

  defp filter_transaction_columns(params) do
    params
    |> Enum.map(fn %{
                     hash: hash,
                     from_account_id: from_account_id,
                     to_account_id: to_account_id,
                     args: args,
                     type: type,
                     nonce: nonce
                   } ->
      %{
        hash: hash,
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        args: args,
        type: type,
        nonce: nonce
      }
    end)
  end

  defp group_transaction_params(transactions_params_without_receipts) do
    grouped = transactions_params_without_receipts |> Enum.group_by(fn tx -> tx[:type] end)

    {grouped[:polyjuice] || [], grouped[:polyjuice_creator] || [],
     grouped[:eth_address_registry] || []}
  end

  defp parse_raw(%{
         "from_id" => from_account_id,
         "to_id" => to_account_id,
         "nonce" => nonce,
         "args" => "0x" <> args
       })
       when to_account_id == "0x0" do
    {{code_hash, hash_type, script_args}, {registry_id, fee_amount_hex_string}} =
      parse_meta_contract_args(args)

    fee_amount = fee_amount_hex_string |> parse_le_number()
    from_account_id = hex_to_number(from_account_id)

    %{
      nonce: hex_to_number(nonce),
      args: "0x" <> args,
      from_account_id: from_account_id,
      to_account_id: hex_to_number(to_account_id),
      type: :polyjuice_creator,
      code_hash: "0x" <> code_hash,
      hash_type: transform_hash_type(hash_type),
      fee_amount: fee_amount,
      fee_registry_id: registry_id,
      script_args: "0x" <> script_args
    }
  end

  defp parse_raw(%{
         "from_id" => from_account_id,
         "to_id" => to_id,
         "nonce" => nonce,
         "args" => "0x" <> args
       }) do
    cond do
      String.starts_with?(args, "ffffff504f4c59") ->
        [is_create, gas_limit, gas_price, value, input_size, input, native_transfer_address_hash] =
          parse_polyjuice_args(args)

        from_account_id = hex_to_number(from_account_id)
        to_account_id = hex_to_number(to_id)

        %{
          type: :polyjuice,
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
          native_transfer_address_hash: native_transfer_address_hash
        }

      to_id == @eth_addr_reg_id ->
        from_account_id = hex_to_number(from_account_id)
        to_account_id = hex_to_number(to_id)

        %{
          type: :eth_address_registry,
          nonce: hex_to_number(nonce),
          args: "0x" <> args,
          from_account_id: from_account_id,
          to_account_id: to_account_id
        }
    end
  end

  defp schedule_work do
    second =
      Application.get_env(:godwoken_explorer, :pending_transaction_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), :fetch, second * 1000)
  end
end
