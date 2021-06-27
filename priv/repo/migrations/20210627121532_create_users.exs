defmodule AttendenceService.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:users, [:school_id])
  end
end
