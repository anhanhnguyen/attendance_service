defmodule AttendenceService.Attendances.AggregateServ do
  use GenServer

  alias AttendenceService.Attendances.AggregateDsup

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def aggregate(from, to, criteria) do
    GenServer.call(__MODULE__, aggregate: {from, to, criteria})
  end

  def inform(info) do
    GenServer.call(__MODULE__, info)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call([aggregate: _condition] = req, from, state) do
    AggregateDsup.start_worker(req ++ [caller: from])
    {:noreply, state}
  end

  def handle_call([result: data, caller: caller], {pid, _ref}, state) do
    GenServer.reply(caller, data)
    GenServer.cast(__MODULE__, terminate_worker: pid)
    {:reply, :thank_you, state}
  end

  def handle_call(req, _from, state) do
    {:reply, req, state}
  end

  def handle_cast([terminate_worker: pid], state) do
    AggregateDsup.terminate_worker(pid)
    {:noreply, state}
  end

  def handle_cast(_req, state) do
    {:noreply, state}
  end
end
