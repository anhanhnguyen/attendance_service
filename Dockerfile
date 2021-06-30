FROM bitwalker/alpine-elixir-phoenix:latest

WORKDIR /app

COPY mix.exs .
COPY mix.lock .

CMD mix deps.get && mix ecto.setup && mix phx.server