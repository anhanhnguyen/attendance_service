defmodule AttendenceServiceWeb.AttendanceController do
  use AttendenceServiceWeb, :controller

  alias AttendenceService.Attendances
  alias AttendenceService.Attendances.Aggregate
  alias AttendenceService.Attendances.Attendance

  action_fallback AttendenceServiceWeb.FallbackController

  def index(conn, _params) do
    attendances = Attendances.list_attendances()
    render(conn, "index.json", attendances: attendances)
  end

  def create(conn, %{"attendance" => attendance_params}) do
    with {:ok, %Attendance{} = attendance} <- Attendances.create_attendance(attendance_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.attendance_path(conn, :show, attendance))
      |> render("show.json", attendance: attendance)
    end
  end

  def show(conn, %{"id" => id}) do
    attendance = Attendances.get_attendance!(id)
    render(conn, "show.json", attendance: attendance)
  end

  def update(conn, %{"id" => id, "attendance" => attendance_params}) do
    attendance = Attendances.get_attendance!(id)

    with {:ok, %Attendance{} = attendance} <-
           Attendances.update_attendance(attendance, attendance_params) do
      render(conn, "show.json", attendance: attendance)
    end
  end

  def delete(conn, %{"id" => id}) do
    attendance = Attendances.get_attendance!(id)

    with {:ok, %Attendance{}} <- Attendances.delete_attendance(attendance) do
      send_resp(conn, :no_content, "")
    end
  end

  def aggregate_by_school(conn, %{"id" => school_id} = params) do
    d_time = Time.new!(0, 0, 0)
    d_day = Date.utc_today()

    from =
      case params["from"] do
        nil -> NaiveDateTime.new!(d_day, d_time)
        date -> NaiveDateTime.new!(Date.from_iso8601!(date), d_time)
      end

    to =
      case params["to"] do
        nil -> NaiveDateTime.new!(Date.add(d_day, 1), d_time)
        date -> NaiveDateTime.new!(Date.add(Date.from_iso8601!(date), 1), d_time)
      end

    with :lt <- NaiveDateTime.compare(from, to) do
      data = Aggregate.by_school(school_id, from, to)
      render(conn, "aggregate.json", school: data)
    else
      _ ->
        send_resp(conn, :bad_request, "")
    end
  end
end
