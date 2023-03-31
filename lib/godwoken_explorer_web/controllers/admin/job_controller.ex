defmodule GodwokenExplorerWeb.Admin.JobController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Admin.Job

  plug(:put_root_layout, {GodwokenExplorerWeb.Layouts, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case Job.paginate_jobs(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Jobs. #{inspect(error)}")
        |> redirect(to: ~p"/admin/jobs")
    end
  end

  def show(conn, %{"id" => id}) do
    job = Job.get_job!(id)
    render(conn, "show.html", job: job)
  end

  def delete(conn, %{"id" => id}) do
    job = Job.get_job!(id)
    {:ok, _job} = Job.delete_job(job)

    conn
    |> put_flash(:info, "Job deleted successfully.")
    |> redirect(to: ~p"/admin/jobs")
  end
end
