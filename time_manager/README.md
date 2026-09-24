# Time Manager API

Elixir / Phoenix / PostgreSQL API to track working times and clocks.

## Requirements
- Elixir 1.18+ (with Erlang/OTP 27)
- PostgreSQL (user `postgres`, password `postgres`, on localhost)

## Run
    mix deps.get
    mix ecto.setup
    mix phx.server

The API is available at http://localhost:4000/api

## Endpoints
- Users: GET/POST /api/users, GET/PUT/DELETE /api/users/:userID
- Working time: GET/POST /api/workingtime/:userID, GET /api/workingtime/:userID/:id, PUT/DELETE /api/workingtime/:id
- Clocks: GET/POST /api/clocks/:userID