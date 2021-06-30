defmodule AttendenceService.Attendances.Aggregate do
  use Supervisor

  alias AttendenceService.Attendances.AggregateServ

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      AttendenceService.Attendances.AggregateServ,
      AttendenceService.Attendances.AggregateDsup,
      {Task.Supervisor, name: AttendenceService.Attendances.AggregateTask}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def by_school(school_id, from, to) do
    AggregateServ.aggregate(from, to, %{school_id: school_id})
  end
end
