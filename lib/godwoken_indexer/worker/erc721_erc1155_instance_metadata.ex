defmodule GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata do
  use Oban.Worker, queue: :default

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Token.InstanceMetadataRetriever
  alias GodowokenExplorer.TokenInstance

  alias GodwokenExplorer.Chain.Hash.Address

  require Logger

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
    :ok
  end

  def do_perform(%{
        "token_contract_address_hash" => token_contract_address_hash,
        "token_id" => token_id
      })
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

      result ->
        Logger.debug(
          [
            "failed to fetch token instance metadata for #{inspect({token_contract_address_hash, token_id})}: ",
            inspect(result)
          ],
          fetcher: :token_instances
        )
    end

    :ok
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
