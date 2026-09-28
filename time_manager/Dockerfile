FROM elixir:1.18.2-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential ca-certificates git postgresql-client \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get

COPY . .
RUN chmod +x ./entrypoint.sh && mix compile

EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["mix", "phx.server"]
