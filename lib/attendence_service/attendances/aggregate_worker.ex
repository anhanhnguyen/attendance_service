defmodule AttendenceService.Attendances.AggregateWorker do
  use GenServer

  import Ecto.Query

  alias AttendenceService.Repo
  alias AttendenceService.Users.User
  alias AttendenceService.Attendances.Attendance
  alias AttendenceService.Attendances.AggregateServ

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(aggregate: condition, caller: caller) do
    GenServer.cast(self(), condition)
    {:ok, %{done: 0, caller: caller}}
  end

  def handle_cast({from, to, criteria}, %{} = state) do
    [school: id, users: users, tasks: tasks] = aggregate(from, to, criteria)

    new_state = %{
      school: id,
      from: from,
      to: to,
      users: users,
      tasks: tasks,
      done: state.done,
      caller: state.caller
    }

    with 0 <- tasks do
      GenServer.cast(self(), :ready_to_inform)
    end

    {:noreply, new_state}
  end

  def handle_cast(:ready_to_inform, %{school: school_id} = state) do
    users = state.users
    ids = Map.keys(users)

    standard = NaiveDateTime.diff(NaiveDateTime.add(state.to, -1), state.from) * 0.8 / 86400

    presences = ids |> Enum.filter(fn id -> users[id] > standard end)
    absences = ids -- presences

    result = %{
      school_id: school_id,
      from: state.from,
      to: state.to,
      presences: length(presences),
      absences: length(absences)
    }

    AggregateServ.inform(result: result, caller: state.caller)
    {:noreply, state}
  end

  def handle_cast(_req, state) do
    {:noreply, state}
  end

  def handle_info({_ref, task_answer}, %{} = state) do
    tasks = state.tasks
    done = state.done + 1

    users =
      task_answer
      |> Enum.reduce(state.users, fn id, acc ->
        case acc[id] do
          nil -> Map.put(acc, id, 1)
          presence_count -> Map.put(acc, id, presence_count + 1)
        end
      end)

    with ^tasks <- done do
      GenServer.cast(self(), :ready_to_inform)
    end

    {:noreply, %{state | users: users, done: done}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info(_req, state) do
    {:noreply, state}
  end

  def aggregate(from, to, %{school_id: school_id}) do
    ts = AttendenceService.Attendances.AggregateTask

    users =
      User
      |> where([u], u.school_id == ^school_id)
      |> select([u], u.id)
      |> Repo.all()
      |> Enum.map(fn e -> {e, 0} end)
      |> Map.new()

    chunks =
      Attendance
      |> where([a], a.inserted_at >= ^from)
      |> where([a], a.inserted_at < ^to)
      |> where([a], a.school_id == ^school_id)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()
      |> Enum.chunk_by(fn %Attendance{inserted_at: time} -> NaiveDateTime.to_date(time) end)
      |> Enum.map(fn attendances ->
        Task.Supervisor.async(ts, fn -> aggregate_by_day(attendances) end)
      end)

    [school: school_id, users: users, tasks: length(chunks)]
  end

  def aggregate_by_day(attendances) do
    acc_by_user =
      attendances
      |> Enum.group_by(fn %Attendance{user_id: user_id} -> user_id end)

    Map.keys(acc_by_user)
    |> Enum.filter(fn id -> present?(Map.get(acc_by_user, id)) end)
  end

  def present?([]) do
    false
  end

  def present?(attendances) do
    today = Date.utc_today()

    with %Attendance{inserted_at: inserted_at, type: :checkin} <- List.first(attendances),
         ^today <- NaiveDateTime.to_date(inserted_at) do
      true
    else
      %Attendance{} ->
        timestamps =
          attendances
          |> Enum.chunk_by(fn %Attendance{type: type} -> type end)
          |> Enum.map(fn
            [%Attendance{type: :checkout, inserted_at: inserted_at} | _] ->
              {seconds, _} = NaiveDateTime.to_gregorian_seconds(inserted_at)
              -seconds

            [%Attendance{type: :checkin} = a | checkins] ->
              case checkins do
                [] ->
                  {seconds, _} = NaiveDateTime.to_gregorian_seconds(a.inserted_at)
                  seconds

                _ ->
                  %Attendance{inserted_at: inserted_at} = hd(Enum.reverse(checkins))
                  {seconds, _} = NaiveDateTime.to_gregorian_seconds(inserted_at)
                  seconds
              end
          end)

        case rem(length(timestamps), 2) do
          0 ->
            timestamps |> Enum.sum() < -7200

          _ ->
            # timestamps |> Enum.reverse() |> Enum.drop(1) |> Enum.sum() < -7
            timestamps |> Enum.reverse() |> Enum.drop(1) |> Enum.sum() < -7200
        end

      _ ->
        attendances |> Enum.drop(1) |> present?()
    end
  end
end
