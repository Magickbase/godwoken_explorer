defmodule GodwokenExplorer.Admin.Job do
  @moduledoc """
  The Oban context.
  """

  import Ecto.Query, warn: false
  alias GodwokenExplorer.Repo

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias Oban.Job

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of jobs using filtrex
  filters.

  ## Examples

      iex> paginate_jobs(%{})
      %{jobs: [%Job{}], ...}

  """
  @spec paginate_jobs(map) :: {:ok, map} | {:error, any}
  def paginate_jobs(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:jobs), params["job"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_jobs(filter, params) do
      {:ok,
       %{
         jobs: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_jobs(filter, params) do
    Job
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of jobs.

  ## Examples

      iex> list_jobs()
      [%Job{}, ...]

  """
  def list_jobs do
    Repo.all(Job)
  end

  @doc """
  Gets a single job.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job!(id), do: Repo.get!(Job, id)

  @doc """
  Deletes a Job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  defp filter_config(:jobs) do
    defconfig do
      text(:state)
      text(:queue)
    end
  end
end
