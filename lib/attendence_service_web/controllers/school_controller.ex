defmodule AttendenceServiceWeb.SchoolController do
  use AttendenceServiceWeb, :controller

  alias AttendenceService.Schools
  alias AttendenceService.Schools.School

  action_fallback AttendenceServiceWeb.FallbackController

  def index(conn, _params) do
    schools = Schools.list_schools()
    render(conn, "index.json", schools: schools)
  end

  def create(conn, %{"school" => school_params}) do
    with {:ok, %School{} = school} <- Schools.create_school(school_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.school_path(conn, :show, school))
      |> render("show.json", school: school)
    end
  end

  def show(conn, %{"id" => id}) do
    school = Schools.get_school!(id)
    render(conn, "show.json", school: school)
  end

  def update(conn, %{"id" => id, "school" => school_params}) do
    school = Schools.get_school!(id)

    with {:ok, %School{} = school} <- Schools.update_school(school, school_params) do
      render(conn, "show.json", school: school)
    end
  end

  def delete(conn, %{"id" => id}) do
    school = Schools.get_school!(id)

    with {:ok, %School{}} <- Schools.delete_school(school) do
      send_resp(conn, :no_content, "")
    end
  end
end
