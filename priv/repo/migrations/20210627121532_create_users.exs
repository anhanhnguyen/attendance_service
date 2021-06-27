defmodule AttendenceService.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:users, [:school_id])
  end
end
