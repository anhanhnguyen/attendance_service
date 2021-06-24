# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :attendence_service,
  ecto_repos: [AttendenceService.Repo]

# Configures the endpoint
config :attendence_service, AttendenceServiceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ayCFYI9FxLl1KyclRKX0UGfKp6vzozrVXft/YcK+BlpBDNBnv2fZOzuxosZ48JmM",
  render_errors: [view: AttendenceServiceWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: AttendenceService.PubSub,
  live_view: [signing_salt: "SrwIWi5P"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
