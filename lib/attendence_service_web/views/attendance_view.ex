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
      timestamp: attendance.inserted_at,
      user_id: attendance.user_id,
      school_id: attendance.school_id,
      temperature: attendance.temperature,
      image: attendance.image,
      type: attendance.type}
  end

  def render("aggregate.json", %{school: aggregate}) do
    %{data: render_one(aggregate, AttendanceView, "school_aggregate.json")}
  end

  def render("school_aggregate.json", %{attendance: attendance}) do
    %{school_id: attendance.school_id,
      from: attendance.from,
      to: NaiveDateTime.add(attendance.to, -1),
      presences: attendance.presences,
      absences: attendance.absences}
  end
end
