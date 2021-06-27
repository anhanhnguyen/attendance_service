defmodule AttendenceService.Attendances.Attendance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attendances" do
    field :image, :string
    field :temperature, :float
    field :type, Ecto.Enum, values: [:checkin, :checkout]

    belongs_to :user, AttendenceService.Users.User
    belongs_to :school, AttendenceService.Schools.School

    timestamps()
  end

  @doc false
  def changeset(attendance, attrs) do
    attendance
    |> cast(attrs, [:user_id, :school_id, :temperature, :image, :type])
    |> validate_required([:user_id, :school_id, :temperature, :type])
    |> validate_number(:temperature, [greater_than: 28, less_than: 43])
    |> assoc_constraint((:user))
    |> assoc_constraint((:school))
  end
end
