defmodule GodwokenExplorer.Chain.Import do
  alias Ecto.Changeset
  alias GodwokenExplorer.Repo

  def insert_changes_list(params, options)
      when is_list(params) do
    ecto_schema_module = Keyword.fetch!(options, :for)
    {:ok, changes_list} = parse_changes_list(params, ecto_schema_module)

    timestamped_changes_list =
      timestamp_changes_list(changes_list, Keyword.fetch!(options, :timestamps))

    {_, inserted} =
      Repo.safe_insert_all(
        ecto_schema_module,
        timestamped_changes_list,
        Keyword.delete(options, :for)
      )

    {:ok, inserted}
  end

  defp parse_changes_list(params, ecto_schema_module) do
    struct = ecto_schema_module.__struct__()

    params
    |> Stream.map(&apply(ecto_schema_module, :changeset, [struct, &1]))
    |> Enum.reduce({:ok, []}, fn
      changeset = %Changeset{valid?: false}, {:ok, _} ->
        {:error, [changeset]}

      changeset = %Changeset{valid?: false}, {:error, acc_changesets} ->
        {:error, [changeset | acc_changesets]}

      %Changeset{changes: changes, valid?: true}, {:ok, acc_changes} ->
        {:ok, [changes | acc_changes]}

      %Changeset{valid?: true}, {:error, _} = error ->
        error

      :ignore, error ->
        {:error, error}
    end)
    |> case do
      {:ok, changes} -> {:ok, changes}
      {:error, _} = error -> error
    end
  end

  @type timestamps :: %{inserted_at: DateTime.t(), updated_at: DateTime.t()}

  defp timestamp_changes_list(changes_list, timestamps) when is_list(changes_list) do
    Enum.map(changes_list, &timestamp_params(&1, timestamps))
  end

  defp timestamp_params(changes, timestamps) when is_map(changes) do
    Map.merge(changes, timestamps)
  end

  @spec timestamps() :: timestamps
  def timestamps do
    now = DateTime.utc_now()
    %{inserted_at: now, updated_at: now}
  end
end
