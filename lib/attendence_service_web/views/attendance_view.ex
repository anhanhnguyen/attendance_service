defmodule AttendenceServiceWeb.AttendanceView do
  use AttendenceServiceWeb, :view
  alias AttendenceServiceWeb.AttendanceView

  def render("index.json", %{attendances: attendances}) do
    %{data: render_many(attendances, AttendanceView, "attendance.json")}
  end

  def render("show.json", %{attendance: attendance}) do
    %{data: render_one(attendance, AttendanceView, "attendance.json")}
  end

  def render("attendance.json", %{attendance: attendance}) do
    %{id: attendance.id,
      temperature: attendance.temperature,
      image: attendance.image}
  end
end
