defmodule AttendenceService.Repo.Migrations.CreateAttendances do
  use Ecto.Migration

  def change do
    create table(:attendances) do
      add :temperature, :integer
      add :image, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:attendances, [:user_id])
    create index(:attendances, [:school_id])
  end
end
