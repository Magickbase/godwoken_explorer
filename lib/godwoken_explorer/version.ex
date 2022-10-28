defmodule GodwokenExplorer.Version do
  @moduledoc """
  Table's version control.
  """
  use GodwokenExplorer, :schema

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "versions" do
    # The patch in Erlang External Term Format
    field :patch, ExAudit.Type.Patch

    # supports UUID and other types as well
    field :entity_id, :integer

    # name of the table the entity is in
    field :entity_schema, ExAudit.Type.Schema

    # type of the action that has happened to the entity (created, updated, deleted)
    field :action, ExAudit.Type.Action

    # when has this happened
    field :recorded_at, :utc_datetime_usec

    # was this change part of a rollback?
    field :rollback, :boolean, default: false

    # custom fields
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:patch, :entity_id, :entity_schema, :action, :recorded_at, :rollback])
  end
end
