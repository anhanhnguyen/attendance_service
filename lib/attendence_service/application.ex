defmodule AttendenceService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      AttendenceService.Repo,
      # Start the Telemetry supervisor
      AttendenceServiceWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AttendenceService.PubSub},
      # Start the Endpoint (http/https)
      AttendenceServiceWeb.Endpoint,
      # Start a worker by calling: AttendenceService.Worker.start_link(arg)
      # {AttendenceService.Worker, arg}
      AttendenceService.Attendances.Aggregate
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AttendenceService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AttendenceServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
