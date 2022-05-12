defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util,
    only: [
      script_to_hash: 1,
      balance_to_view: 2,
      import_timestamps: 0,
      integer_to_le_binary: 1,
      pad_trailing: 3
    ]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher

  @polyjuice_creator_args_length 82
  @yok_mainnet_account_id 12119

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field(:eth_address, :binary)
    field(:script_hash, :binary)
    field(:registry_address, :binary)
    field(:script, :map)
    field(:nonce, :integer)
    field(:transaction_count, :integer)
    field(:token_transfer_count, :integer)
    field(:contract_code, :binary)

    field(:type, Ecto.Enum,
      values: [
        :meta_contract,
        :udt,
        :eth_user,
        :polyjuice_creator,
        :polyjuice_contract,
        :eth_addr_reg,
        :unknown
      ]
    )

    has_many(:account_udts, AccountUDT)
    has_one(:smart_contract, SmartContract)

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :id,
      :eth_address,
      :script_hash,
      :script,
      :nonce,
      :type,
      :registry_address,
      :transaction_count,
      :token_transfer_count,
      :contract_code
    ])
    |> validate_required([:id, :script_hash])
  end

  def create_or_update_account!(attrs) do
    case Repo.get_by(__MODULE__, script_hash: attrs[:script_hash]) do
      nil -> %__MODULE__{}
      account -> account
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
    |> case do
      account = %Account{} ->
        account_api_data = account.id |> find_by_id() |> account_to_view()
        Publisher.broadcast([{:accounts, account_api_data}], :realtime)
        {:ok, account}

      {:error, error_msg} ->
        Logger.error("Failed to create or update account: #{inspect(error_msg)}")
        {:error, nil}
    end
  end

  def count() do
    from(
      a in Account,
      select: fragment("COUNT(*)")
    )
    |> Repo.one(timeout: :infinity)
  end

  def update_meta_contract(global_state) do
    case Repo.get(Account, 0) do
      %Account{} = meta_contract ->
        atom_script =
          for {key, val} <- meta_contract.script, into: %{}, do: {String.to_atom(key), val}

        new_script = atom_script |> Map.merge(global_state)

        case meta_contract
             |> Ecto.Changeset.change(script: new_script)
             |> Repo.update() do
          {:ok, account} ->
            account_api_data = 0 |> find_by_id() |> account_to_view()
            Publisher.broadcast([{:accounts, account_api_data}], :realtime)
            {:ok, account}

          {:error, schema} ->
            {:error, schema}
        end

      nil ->
        manual_create_account!(0)
    end
  end

  def find_by_id(id) do
    account = Repo.get(Account, id)

    ckb_balance =
      with udt_id when is_integer(udt_id) <- UDT.ckb_account_id(),
           {:ok, balance} <- GodwokenRPC.fetch_balance(account.registry_address, udt_id) do
        balance
      else
        _ -> ""
      end

    base_map = %{
      id: id,
      type: account.type,
      ckb: ckb_balance,
      tx_count: account.transaction_count || 0,
      transfer_count: account.token_transfer_count || 0,
      eth_addr: elem(display_id(id), 0)
    }

    case account do
      %Account{type: :meta_contract} ->
        %{
          meta_contract: %{
            account_merkle_state: account.script["account_merkle_state"],
            block_merkle_state: account.script["block_merkle_state"],
            reverted_block_root: account.script["reverted_block_root"],
            last_finalized_block_number: account.script["last_finalized_block_number"],
            status: account.script["status"]
          }
        }

      %Account{type: type, eth_address: eth_address} when type == :eth_user ->
        udt_list = AccountUDT.list_udt_by_eth_address(eth_address)

        %{
          user: %{
            nonce: account.nonce |> Integer.to_string(),
            udt_list: udt_list
          }
        }

      %Account{type: :polyjuice_creator} ->
        %{
          polyjuice: %{
            script: account.script
          }
        }

      %Account{type: :polyjuice_contract, eth_address: eth_address} ->
        account = account |> Repo.preload(:smart_contract)
        udt_list = AccountUDT.list_udt_by_eth_address(eth_address)

        case account.smart_contract do
          smart_contract = %SmartContract{} ->
            %{
              smart_contract: %{
                # create account's tx_hash needs godwoken api support
                tx_hash: "",
                abi: smart_contract.abi,
                contract_source_code: smart_contract.contract_source_code,
                name: smart_contract.name,
                constructor_arguments: smart_contract.constructor_arguments,
                deployment_tx_hash: smart_contract.deployment_tx_hash,
                compiler_version: smart_contract.compiler_version,
                compiler_file_format: smart_contract.compiler_file_format,
                other_info: smart_contract.other_info,
                creator_address: SmartContract.creator_address(smart_contract),
                udt_list: udt_list
              }
            }

          _ ->
            %{
              smart_contract: %{
                # create account's tx_hash needs godwoken api support
                tx_hash: "",
                udt_list: udt_list
              }
            }
        end

      %Account{type: :udt, id: id} ->
        udt = Repo.get(UDT, id)

        if is_nil(udt) do
          %{
            sudt: %{
              name: "Unknown##{id}"
            }
          }
        else
          holders = UDT.count_holder(id)

          type_script =
            if id == UDT.ckb_account_id() do
              nil
            else
              udt.type_script
            end

          %{
            sudt: %{
              name: udt.name || "Unknown##{id}",
              symbol: udt.symbol,
              icon: udt.icon,
              decimal: udt.decimal,
              supply: (udt.supply || Decimal.new(0)) |> Decimal.to_string(:normal),
              holders: holders || 0,
              type_script: type_script,
              script_hash: account.script_hash
            }
          }
        end

      _ ->
        %{
          polyjuice: %{
            script: account.script
          }
        }
    end
    |> Map.merge(base_map)
  end

  def account_to_view(account) do
    account =
      Map.merge(account, %{
        ckb: balance_to_view(account.ckb, 18)
      })

    case Kernel.get_in(account, [:eth_user, :udt_list]) do
      udt_list when not is_nil(udt_list) ->
        Kernel.put_in(
          account,
          [:eth_user, :udt_list],
          udt_list
          |> Enum.map(fn udt ->
            %{udt | balance: udt.balance |> D.to_string(:normal)}
          end)
        )

      _ ->
        account
    end
  end

  def search(keyword) do
    results =
      from(a in Account,
        where: a.eth_address == ^keyword or a.script_hash == ^keyword,
        order_by: a.id
      )
      |> Repo.all()

    if length(results) > 1 do
      Logger.error("Same keyword Error: #{keyword}")
      nil
    else
      results |> List.first()
    end
  end

  def find_or_create_udt_account!(
        udt_script,
        udt_script_hash,
        l1_block_number \\ 0,
        tip_block_number \\ 0
      ) do
    case Repo.get_by(UDT, script_hash: udt_script_hash) do
      %UDT{id: id} ->
        {:ok, id}

      nil ->
        l2_udt_code_hash = Application.get_env(:godwoken_explorer, :l2_udt_code_hash)
        rollup_type_hash = Application.get_env(:godwoken_explorer, :rollup_type_hash)

        account_script = %{
          "code_hash" => l2_udt_code_hash,
          "hash_type" => "type",
          "args" => rollup_type_hash <> String.slice(udt_script_hash, 2..-1)
        }

        l2_udt_script_hash = script_to_hash(account_script)

        case GodwokenRPC.fetch_account_id(l2_udt_script_hash) do
          {:error, :account_slow} ->
            if l1_block_number + 100 > tip_block_number do
              raise "account may not created now at #{l1_block_number}"
            end

          {:error, :network_error} ->
            {:error, nil}

          {:ok, udt_account_id} ->
            {:ok, _udt} =
              UDT.find_or_create_by(%{
                id: udt_account_id,
                script_hash: udt_script_hash,
                type_script: udt_script
              })

            __MODULE__.create_or_update_account!(%{
              id: udt_account_id,
              script: account_script,
              script_hash: l2_udt_script_hash,
              type: "udt"
            })

            {:ok, udt_account_id}
        end
    end
  end

  def find_or_create_contract_by_eth_address(eth_address) do
    case Repo.get_by(__MODULE__, %{eth_address: eth_address}) do
      %__MODULE__{} = account ->
        {:ok, account}

      nil ->
        polyjuice_validator_code_hash =
          Application.get_env(:godwoken_explorer, :polyjuice_validator_code_hash)

        rollup_type_hash = Application.get_env(:godwoken_explorer, :rollup_type_hash)
        polyjuice_creator_id = Application.get_env(:godwoken_explorer, :polyjuice_creator_id)

        le_hex_polyjuice_creator_id =
          polyjuice_creator_id
          |> integer_to_le_binary()
          |> pad_trailing(4, 0)
          |> Base.encode16(case: :lower)

        account_script = %{
          "code_hash" => polyjuice_validator_code_hash,
          "hash_type" => "type",
          "args" =>
            rollup_type_hash <> le_hex_polyjuice_creator_id <> String.slice(eth_address, 2..-1)
        }

        script_hash = script_to_hash(account_script)
        {:ok, account_id} = GodwokenRPC.fetch_account_id(script_hash)
        account = Account.manual_create_account!(account_id)
        {:ok, account}
    end
  end

  def switch_account_type(code_hash, args) do
    polyjuice_code_hash = Application.get_env(:godwoken_explorer, :polyjuice_validator_code_hash)
    eth_eoa_type_hash = Application.get_env(:godwoken_explorer, :eth_eoa_type_hash)
    l2_udt_code_hash = Application.get_env(:godwoken_explorer, :l2_udt_code_hash)

    meta_contract_validator_type_hash =
      Application.get_env(:godwoken_explorer, :meta_contract_validator_type_hash)

    eth_addr_reg_type_hash =
      Application.get_env(:godwoken_explorer, :eth_addr_reg_validator_script_type_hash)

    case code_hash do
      ^meta_contract_validator_type_hash ->
        :meta_contract

      ^l2_udt_code_hash ->
        :udt

      ^polyjuice_code_hash when byte_size(args) == @polyjuice_creator_args_length ->
        :polyjuice_creator

      ^polyjuice_code_hash ->
        :polyjuice_contract

      ^eth_eoa_type_hash ->
        :eth_user

      ^eth_addr_reg_type_hash ->
        :eth_addr_reg

      _ ->
        :unknown
    end
  end

  def script_to_eth_adress(type, args) do
    rollup_type_hash = Application.get_env(:godwoken_explorer, :rollup_type_hash)

    if type in [:eth_user, :polyjuice_contract] &&
         args |> String.slice(0, 66) == rollup_type_hash do
      "0x" <> String.slice(args, -40, 40)
    else
      nil
    end
  end

  def non_create_account_info(eth_address) do
    udt_list = AccountUDT.list_udt_by_eth_address(eth_address)

    %{
      id: nil,
      type: :unknown,
      ckb: "0",
      tx_count: 0,
      eth_addr: eth_address,
      user: %{
        nonce: 0,
        udt_list: udt_list
      }
    }
  end

  def display_id(id) do
    case from(a in Account,
           left_join: s in SmartContract,
           on: s.account_id == a.id,
           where: a.id == ^id,
           select: %{
             type: a.type,
             eth_address: a.eth_address,
             script_hash: a.script_hash,
             contract_name: s.name
           }
         )
         |> Repo.one() do
      %{
        type: type,
        eth_address: eth_address,
        contract_name: contract_name,
        script_hash: script_hash
      } ->
        cond do
          type in [:eth_user, :polyjuice_contract] -> {eth_address, eth_address}
          type == :udt -> {script_hash, contract_name || script_hash}
          type == :polyjuice_creator -> {script_hash, "Deploy Contract"}
          type == :meta_contract -> {script_hash, "Meta Contract"}
          type == :eth_addr_reg -> {script_hash, "Eth Address Registry"}
          true -> {id, id}
        end

      nil ->
        with {:ok, script_hash} <- GodwokenRPC.fetch_script_hash(%{account_id: id}),
             {:ok, script} <- GodwokenRPC.fetch_script(script_hash) do
          type = switch_account_type(script["code_hash"], script["args"])

          registry_address =
            if type in [:eth_user, :polyjuice_contract] do
              {:ok, registry_address} = GodwokenRPC.fetch_registry_address(script_hash)
              registry_address
            else
              nil
            end

          cond do
            type in [:eth_user, :polyjuice_contract] ->
              {Account.script_to_eth_adress(type, script["args"]),
               Account.script_to_eth_adress(type, script["args"])}

            type == :polyjuice_creator ->
              {registry_address, "Deploy Contract"}

            type == :meta_contract ->
              {registry_address, "Meta Contract"}

            type == :eth_addr_reg ->
              {registry_address, "Eth Address Registry"}

            type == :udt ->
              {script_hash, script_hash}

            true ->
              {id, id}
          end
        else
          {:error, :network_error} -> {id, id}
        end
    end
  end

  def display_ids(ids) do
    results =
      from(a in Account,
        left_join: s in SmartContract,
        on: s.account_id == a.id,
        where: a.id in ^ids,
        select: %{
          id: a.id,
          type: a.type,
          eth_address: a.eth_address,
          contract_name: s.name,
          script_hash: a.script_hash
        }
      )
      |> Repo.all()

    results
    |> Enum.into(%{}, fn %{
                           id: id,
                           type: type,
                           eth_address: eth_address,
                           contract_name: contract_name,
                           script_hash: script_hash
                         } ->
      {id,
       cond do
         type in [:eth_user, :polyjuice_contract] -> {eth_address, eth_address}
         type == :udt -> {script_hash, contract_name || script_hash}
         type == :polyjuice_creator -> {script_hash, "Deploy Contract"}
         type == :meta_contract -> {script_hash, "Meta Contract"}
         type == :eth_addr_reg -> {script_hash, "Eth Address Registry"}
         true -> {id, id}
       end}
    end)
  end

  def batch_import_accounts(ids) do
    params = ids |> Enum.map(&%{account_id: &1})
    {:ok, %{errors: [], params_list: script_hash_list}} = GodwokenRPC.fetch_script_hashes(params)
    {:ok, %{errors: [], params_list: script_list}} = GodwokenRPC.fetch_scripts(script_hash_list)

    {:ok, %{errors: [], params_list: registry_address_list}} =
      GodwokenRPC.fetch_registry_addresses(script_hash_list)

    account_list =
      (script_hash_list ++ script_list ++ registry_address_list)
      |> Enum.group_by(&Map.get(&1, :script_hash))
      |> Enum.map(fn {_, list} ->
        Enum.concat(list)
        |> Enum.into(%{})
      end)

    account_attrs =
      account_list
      |> Enum.map(fn %{
                       account_id: account_id,
                       script: script
                     } = account ->
        type = switch_account_type(script["code_hash"], script["args"])
        eth_address = script_to_eth_adress(type, script["args"])

        account
        |> Map.merge(%{
          id: account_id,
          type: type,
          nonce: 0,
          eth_address: eth_address
        })
        |> Map.drop([:account_id])
        |> Map.merge(import_timestamps())
      end)

    Repo.insert_all(Account, account_attrs, on_conflict: :nothing)
  end

  def manual_create_account!(id) do
    with {:ok, script_hash}
         when script_hash != "0x0000000000000000000000000000000000000000000000000000000000000000" <-
           GodwokenRPC.fetch_script_hash(%{account_id: id}) do
      nonce = GodwokenRPC.fetch_nonce(id)
      {:ok, script} = GodwokenRPC.fetch_script(script_hash)
      type = switch_account_type(script["code_hash"], script["args"])

      registry_address =
        if type in [:eth_user, :polyjuice_contract] do
          {:ok, registry_address} = GodwokenRPC.fetch_registry_address(script_hash)
          registry_address
        else
          nil
        end

      eth_address = script_to_eth_adress(type, script["args"])

      attrs = %{
        id: id,
        script: script,
        script_hash: script_hash,
        registry_address: registry_address,
        type: type,
        nonce: nonce,
        eth_address: eth_address
      }

      case Repo.get_by(__MODULE__, script_hash: attrs[:script_hash]) do
        nil -> %__MODULE__{}
        account -> account
      end
      |> changeset(attrs)
      |> Repo.insert_or_update!()
    end
  end

  def update_nonce!(id) do
    nonce = GodwokenRPC.fetch_nonce(id)
    Repo.get(Account, id) |> changeset(%{nonce: nonce}) |> Repo.update!()
  end

  def update_all_nonce!(ids) do
    params = ids |> Enum.map(fn id -> %{account_id: id} end)
    {:ok, responses} = GodwokenRPC.fetch_nonce_by_ids(params)

    changes =
      responses
      |> Enum.map(fn m ->
        Map.merge(m, %{
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })
      end)

    Repo.insert_all(Account, changes,
      on_conflict: {:replace, [:nonce, :updated_at]},
      conflict_target: :id
    )
  end

  def yok_contract_code do
    if FastGlobal.get(:yok_contract_code) do
      FastGlobal.get(:yok_contract_code)
    else
      account = Repo.get(Account, @yok_mainnet_account_id)
      FastGlobal.put(:yok_contract_code, account.contract_code)
      account.contract_code
    end
  end
end
