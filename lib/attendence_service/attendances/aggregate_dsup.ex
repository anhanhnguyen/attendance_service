defmodule AttendenceService.Attendances.AggregateDsup do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_worker(args) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {AttendenceService.Attendances.AggregateWorker, args}
    )
  end

  def terminate_worker(pid) do
    # with {:messages, []} <- Process.info(pid, :messages) do
    # end
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
