defmodule AttendenceService.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string

    belongs_to :school, AttendenceService.Schools.School
    has_many :attendaces, AttendenceService.Attendances.Attendance

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :school_id])
    |> validate_required([:name, :school_id])
    |> assoc_constraint(:school)
  end
end
