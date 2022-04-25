defmodule GodwokenIndexer.Worker.CheckAccount do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, KeyValue, Account}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    key_value =
      case Repo.get_by(KeyValue, key: :last_account_total_count) do
        nil ->
          {:ok, key_value} =
            %KeyValue{}
            |> KeyValue.changeset(%{key: :last_account_total_count, value: "0"})
            |> Repo.insert()

          key_value

        %KeyValue{} = key_value ->
          key_value
      end

    last_count = key_value.value |> String.to_integer()

    with %Account{script: script} when not is_nil(script) <- Account |> Repo.get(0),
         account_count when account_count != nil <-
           get_in(script, ["account_merkle_state", "account_count"]) do
      total_count = account_count - 1

      if last_count <= total_count do
        database_ids =
          from(a in Account,
            where: a.id >= ^last_count,
            select: a.id
          )
          |> Repo.all()

        less_ids = ((last_count..total_count |> Enum.to_list()) -- database_ids) |> Enum.sort()

        Repo.transaction(
          fn ->
            less_ids |> Enum.each(fn x -> Account.manual_create_account!(x) end)

            KeyValue.changeset(key_value, %{value: Integer.to_string(total_count + 1)})
            |> Repo.update!()
          end,
          timeout: :infinity
        )
      end
    end

    :ok
  end
end
