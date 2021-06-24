defmodule AttendenceService.Repo do
  use Ecto.Repo,
    otp_app: :attendence_service,
    adapter: Ecto.Adapters.Postgres
end
