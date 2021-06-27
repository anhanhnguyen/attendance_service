defmodule AttendenceService.Repo.Migrations.CreateAttendances do
  use Ecto.Migration

  def change do
    create table(:attendances) do
      add :temperature, :float, null: false
      add :image, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create_query = "CREATE TYPE check_type AS ENUM ('checkin', 'checkout')"
    drop_query = "DROP TYPE check_type"
    execute(create_query, drop_query)

    alter table(:attendances) do
      add :type, :check_type, null: false
    end

    create index(:attendances, [:user_id])
    create index(:attendances, [:school_id])
  end
end
