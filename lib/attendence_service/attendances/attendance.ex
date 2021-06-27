defmodule AttendenceService.Attendances.Attendance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attendances" do
    field :image, :string
    field :temperature, :integer
    field :user_id, :id
    field :school_id, :id

    timestamps()
  end

  @doc false
  def changeset(attendance, attrs) do
    attendance
    |> cast(attrs, [:temperature, :image])
    |> validate_required([:temperature, :image])
  end
end
