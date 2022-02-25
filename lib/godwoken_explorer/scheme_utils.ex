defmodule GodwokenExplorer.SchemeUtils do
  def base_fields_without_id(mod) do
    mod.__schema__(:fields) -- [:id, :inserted_at, :updated_at]
  end

  def base_fields(mod) do
    mod.__schema__(:fields) -- [:inserted_at, :updated_at]
  end
end
