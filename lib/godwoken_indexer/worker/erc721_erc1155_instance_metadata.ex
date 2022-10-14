defmodule GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata do
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Token.InstanceMetadataRetriever
  alias GodowokenExplorer.TokenInstance

  alias GodwokenExplorer.Chain.Hash.Address

  alias GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata

  require Logger

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "token_contract_address_hash" => token_contract_address_hash,
            "token_id" => token_id
          } = args
      })
      when is_bitstring(token_contract_address_hash) and is_integer(token_id) do
    do_perform(args)
  end

  def new_job(args)
      when is_list(args) do
    args
    |> pre_check()
    |> Enum.each(fn arg ->
      arg
      |> ERC721ERC1155InstanceMetadata.new()
      |> Oban.insert()
    end)
  end

  def pre_check(args) when is_list(args) do
    check_list =
      Enum.map(args, fn %{
                          "token_contract_address_hash" => token_contract_address_hash,
                          "token_id" => token_id
                        } ->
        {:ok, token_contract_address_hash} = Address.cast(token_contract_address_hash)
        token_id = Decimal.new(token_id)
        [token_contract_address_hash, token_id]
      end)

    q =
      from(t in TokenInstance,
        where: fragment("(?, ?)", t.token_contract_address_hash, t.token_id) in ^check_list
      )

    existed = Repo.all(q)

    (check_list -- existed)
    |> Enum.map(
      &%{
        "token_contract_address_hash" => &1.token_contract_address_hash |> to_string,
        "token_id" => &1.token_id |> Decimal.to_integer()
      }
    )
  end

  def do_perform(
        %{
          "token_contract_address_hash" => token_contract_address_hash,
          "token_id" => token_id
        } = _args
      )
      when is_bitstring(token_contract_address_hash) and is_integer(token_id) do
    case InstanceMetadataRetriever.fetch_metadata(token_contract_address_hash, token_id) do
      {:ok, %{metadata: metadata}} ->
        params = %{
          token_id: token_id,
          token_contract_address_hash: token_contract_address_hash,
          metadata: metadata,
          error: nil
        }

        token_instance_upsert(params)

      {:ok, %{error: error}} ->
        params = %{
          token_id: token_id,
          token_contract_address_hash: token_contract_address_hash,
          error: error
        }

        token_instance_upsert(params)

      {:error, :timeout} ->
        params = %{
          token_id: token_id,
          token_contract_address_hash: token_contract_address_hash,
          error: "timeout"
        }

        token_instance_upsert(params)

      result ->
        Logger.info(
          [
            "failed to fetch token instance metadata for #{inspect({token_contract_address_hash, token_id})}: ",
            inspect(result)
          ],
          fetcher: :token_instances
        )

        {:error, :fail}
    end
  end

  def token_instance_upsert(params) do
    changeset = TokenInstance.changeset(%TokenInstance{}, params)

    Repo.insert(changeset,
      on_conflict: :replace_all,
      conflict_target: [:token_id, :token_contract_address_hash]
    )
  end

  def check_token_instance_retrieved(%{
        "token_contract_address_hash" => token_contract_address_hash,
        "token_id" => token_id
      })
      when is_bitstring(token_contract_address_hash) and is_integer(token_id) do
    {:ok, token_contract_address_hash} = Address.cast(token_contract_address_hash)
    token_id = Decimal.new(token_id)

    with return when not is_nil(return) <-
           Repo.get_by(TokenInstance,
             token_contract_address_hash: token_contract_address_hash,
             token_id: token_id
           ),
         _metadata when not is_nil(return) <- return.metadata do
      true
    else
      _ ->
        false
    end
  end
end
