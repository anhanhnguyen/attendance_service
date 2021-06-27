defmodule AttendenceService.AttendancesTest do
  use AttendenceService.DataCase

  alias AttendenceService.Attendances

  describe "attendances" do
    alias AttendenceService.Attendances.Attendance

    @valid_attrs %{image: "some image", temperature: 42}
    @update_attrs %{image: "some updated image", temperature: 43}
    @invalid_attrs %{image: nil, temperature: nil}

    def attendance_fixture(attrs \\ %{}) do
      {:ok, attendance} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Attendances.create_attendance()

      attendance
    end

    test "list_attendances/0 returns all attendances" do
      attendance = attendance_fixture()
      assert Attendances.list_attendances() == [attendance]
    end

    test "get_attendance!/1 returns the attendance with given id" do
      attendance = attendance_fixture()
      assert Attendances.get_attendance!(attendance.id) == attendance
    end

    test "create_attendance/1 with valid data creates a attendance" do
      assert {:ok, %Attendance{} = attendance} = Attendances.create_attendance(@valid_attrs)
      assert attendance.image == "some image"
      assert attendance.temperature == 42
    end

    test "create_attendance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attendances.create_attendance(@invalid_attrs)
    end

    test "update_attendance/2 with valid data updates the attendance" do
      attendance = attendance_fixture()
      assert {:ok, %Attendance{} = attendance} = Attendances.update_attendance(attendance, @update_attrs)
      assert attendance.image == "some updated image"
      assert attendance.temperature == 43
    end

    test "update_attendance/2 with invalid data returns error changeset" do
      attendance = attendance_fixture()
      assert {:error, %Ecto.Changeset{}} = Attendances.update_attendance(attendance, @invalid_attrs)
      assert attendance == Attendances.get_attendance!(attendance.id)
    end

    test "delete_attendance/1 deletes the attendance" do
      attendance = attendance_fixture()
      assert {:ok, %Attendance{}} = Attendances.delete_attendance(attendance)
      assert_raise Ecto.NoResultsError, fn -> Attendances.get_attendance!(attendance.id) end
    end

    test "change_attendance/1 returns a attendance changeset" do
      attendance = attendance_fixture()
      assert %Ecto.Changeset{} = Attendances.change_attendance(attendance)
    end
  end
end
