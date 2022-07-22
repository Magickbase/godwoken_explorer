defmodule GodwokenExplorer.Graphql.Types.Custom.NaiveDateTime do
  use Absinthe.Schema.Notation

  # alias Absinthe.Blueprint.Input

  @desc """
  The NaiveDateTime struct contains the fields year, month, day, hour, minute, second, microsecond and calendar.
  We call them "naive" because this datetime representation does not have a time zone. This means the datetime may not actually exist in certain areas in the world even though it is valid.
  For example, when daylight saving changes are applied by a region, the clock typically moves forward or backward by one hour. This means certain datetimes never occur or may occur more than once. Since NaiveDateTime is not validated against a time zone, such errors would go unnoticed.
  Converts the given naive datetime to ISO 8601:2019.
  """

  scalar :naive_datetime, name: "NaiveDateTime" do
    serialize(&NaiveDateTime.to_iso8601/1)
    parse(&parse_datetime/1)
  end

  @spec parse_datetime(Absinthe.Blueprint.Input.String.t()) :: {:ok, NaiveDateTime.t()} | :error
  @spec parse_datetime(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> {:ok, datetime}
      _error -> :error
    end
  end

  defp parse_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_datetime(_) do
    :error
  end
end
