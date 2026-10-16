# Time Manager — Run & Defence Guide

Everything you need in one place: logins, the commands to start each part
(Ubuntu and PowerShell), and a full Docker explanation line by line.

================================================================
## 1. LOGINS (same accounts for web AND mobile app)
================================================================

These are created automatically by the seed file (priv/repo/seeds.exs)
and by Docker on startup. Same credentials everywhere.

| Role     | Email                 | Password      | What they can do |
|----------|-----------------------|---------------|------------------|
| Admin    | admin@gotham.city     | Admin1234!    | Everything: all users, create/delete users, change roles, manage all teams |
| Manager  | manager@gotham.city   | Manager1234!  | See all users, manage the teams they lead, see their team members' data |
| Employee | employee@gotham.city  | Employee1234! | Only their own clock, working times and profile |

Demo team: "City Hall" — manager = Gordon (manager), member = Bruce (employee).

To make a brand-new account: use "Sign up" on the web or the app.
Every sign-up is an EMPLOYEE; only an admin can promote someone afterward.

================================================================
## 2. WHICH TERMINAL FOR WHAT
================================================================

- UBUNTU (WSL): the API (Elixir/mix) and database commands.
  Prompt looks like:  uzair@DESKTOP-...:~$
  Paths look like:    /mnt/c/Users/user/...
- POWERSHELL (Windows): the web front-end (npm), the mobile app (Capacitor),
  git, and Android tools.
  Prompt looks like:  PS C:\Users\user\...>
  Paths look like:    C:\Users\user\...
- Rule of thumb: "mix ..." = Ubuntu. "npm ...", "npx ...", "git ..." = PowerShell.

================================================================
## 3. RUN EVERYTHING THE NORMAL WAY (for development / the demo)
================================================================

Start these in order. Keep each window open while demoing.

### 3a. Database (once per PC restart) — UBUNTU
    sudo service postgresql start

### 3b. API — UBUNTU
    cd /mnt/c/Users/user/Documents/GitHub/Gotham_Time_Manager/time_manager
    mix phx.server
# Wait for: "Running TimeManagerWeb.Endpoint ... at 0.0.0.0:4000"
# API is now at http://localhost:4000

### 3c. Web front-end — POWERSHELL
    cd C:\Users\user\Documents\GitHub\Gotham_Time_Manager\time_manager_frontend
    npm run serve
# Wait for: "App running at: Local: http://localhost:8080/"
# Open http://localhost:8080 in the browser

### 3d. Mobile app — POWERSHELL (emulator must be open in Android Studio)
    cd C:\Users\user\Documents\GitHub\Gotham_Time_Manager\time_manager_mobile
    npm run build
    npx cap sync
    cd android ; .\gradlew installDebug ; cd ..
    adb shell am start -n city.gotham.timemanager/.MainActivity

### First time only / after a code change to the DB
# Rebuild the database and recreate the demo accounts — UBUNTU
    cd /mnt/c/Users/user/Documents/GitHub/Gotham_Time_Manager/time_manager
    mix ecto.reset

================================================================
## 4. RUN EVERYTHING WITH DOCKER (one command)
================================================================

Needs Docker Desktop open ("Engine running"). Stop the normal servers first
so ports 4000, 8080 and 5432 are free (Ctrl+C in each; also "sudo service
postgresql stop" in Ubuntu so Docker's Postgres can use 5432).

### POWERSHELL (from the repo root)
    cd C:\Users\user\Documents\GitHub\Gotham_Time_Manager
    docker compose up --build
# Watch the logs: migrations run, then "Seeds done...", then the server starts.
# Web:  http://localhost:8080      API: http://localhost:4000

### Stop it
    Ctrl+C
# Remove the containers (keeps the database volume):
    docker compose down
# Remove everything including the database:
    docker compose down -v

### Useful Docker commands
    docker compose ps          # which containers are running
    docker compose logs -f     # follow the logs of all services
    docker compose logs phoenix # logs of just the API
    docker ps                  # all running containers
    docker compose build       # rebuild images without starting

================================================================
## 5. DOCKER EXPLAINED (line by line, for the oral)
================================================================

### Core ideas (say these first)
- An IMAGE is a blueprint: a frozen snapshot of an OS + your code + its deps.
- A CONTAINER is a running instance of an image (like an object from a class).
- A VOLUME is storage that survives even when a container is deleted
  (so the database data is not lost on restart).
- docker-compose.yml describes several containers and how they connect,
  so the whole stack starts with one command.
- Why Docker? Everyone gets the EXACT same environment — no "works on my
  machine". And it starts with a single command.

### docker-compose.yml  (3 services = 3 containers)
    services:
      db:                         # the PostgreSQL database
        image: postgres:15        # use the official Postgres 15 image (not built, downloaded)
        environment:              # Postgres reads these to create the DB + user
          POSTGRES_USER: ${PGUSER}        # ${...} values come from the .env file
          POSTGRES_PASSWORD: ${PGPASSWORD}
          POSTGRES_DB: ${PGDATABASE}
        volumes:
          - db_data:/var/lib/postgresql/data  # store DB files in a named volume -> data survives restarts
        ports:
          - "5432:5432"           # expose DB port to the host (host:container)

      phoenix:                    # the API
        build: ./time_manager     # build from the Dockerfile in that folder (our code)
        env_file: .env            # load all the PG* variables from .env
        environment:
          PGHOST: db              # the API reaches the DB by the service name "db"
        depends_on:
          - db                    # start db first (order only, not "wait until ready")
        ports:
          - "4000:4000"           # API reachable at localhost:4000

      front:                      # the web app, served by nginx
        build: ./time_manager_frontend
        depends_on:
          - phoenix
        ports:
          - "8080:80"             # host 8080 -> nginx port 80 in the container

    volumes:
      db_data:                    # declare the named volume used above

# KEY POINT for the oral: inside the compose network, containers talk to each
# other by SERVICE NAME. That's why PGHOST is "db", not "localhost".

### .env  (values injected into compose)
    PGUSER=postgres
    PGPASSWORD=postgres
    PGDATABASE=time_manager_dev
    PGPORT=5432
    PGHOST=db
# Keeping settings here (not hard-coded) means you change them in one place.
# In real production these would be secrets, not committed.

### time_manager/Dockerfile  (how the API image is built)
    FROM elixir:1.18.2-slim       # start from an official Elixir image
    RUN apt-get update && apt-get install -y build-essential ... postgresql-client ...
                                  # install OS tools: a C compiler (bcrypt needs it)
                                  # and pg_isready (used by entrypoint to wait for the DB)
    WORKDIR /app                  # all next commands run in /app
    RUN mix local.hex --force && mix local.rebar --force   # install Elixir's package tools
    COPY mix.exs mix.lock ./      # copy ONLY the dependency files first ...
    COPY config ./config
    RUN mix deps.get              # ... download deps. This layer is CACHED:
                                  # deps are re-fetched only if mix.exs changes (faster rebuilds)
    COPY . .                      # now copy the rest of the source code
    RUN chmod +x ./entrypoint.sh && mix compile   # make the start script runnable, compile
    EXPOSE 4000                   # document that the app listens on 4000
    ENTRYPOINT ["./entrypoint.sh"] # always run this script on container start
    CMD ["mix", "phx.server"]      # ... with this as its argument ($@) -> starts the server

# KEY POINT: copying mix.exs before the code is a CACHE trick. Docker builds in
# layers; unchanged layers are reused, so you don't re-download deps every build.

### time_manager/entrypoint.sh  (runs each time the API container starts)
    #!/bin/sh
    set -e                        # stop immediately if any command fails
    : "${PGUSER:?PGUSER is required}"   # fail early if a required var is missing
    ...
    export PGPORT PGHOST
    # Wait for Postgres to actually accept connections (depends_on only sets order):
    until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do sleep 1; done
    mix ecto.create || true       # create the DB (ignore error if it already exists)
    mix ecto.migrate              # run migrations (build the tables)
    mix run priv/repo/seeds.exs   # create admin/manager/employee accounts
    exec "$@"                     # replace the shell with the CMD (mix phx.server)

# KEY POINT: depends_on guarantees START ORDER, not readiness. So we actively
# WAIT for Postgres with pg_isready before migrating. This is the classic
# "wait for the DB" pattern.

### time_manager_frontend/Dockerfile  (MULTI-STAGE build)
    FROM node:18 AS build         # STAGE 1 "build": a Node image to compile Vue
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci --silent           # install exact deps from package-lock.json
    COPY . .
    RUN npm run build             # produces the static site in /app/dist

    FROM nginx:stable-alpine      # STAGE 2: a tiny web server image
    COPY --from=build /app/dist /usr/share/nginx/html   # copy ONLY the built files
    COPY nginx.conf /etc/nginx/conf.d/default.conf      # our routing config
    EXPOSE 80
    CMD ["nginx", "-g", "daemon off;"]   # run nginx in the foreground

# KEY POINT: multi-stage build = compile in a big Node image, then ship only the
# finished static files in a small nginx image. Node and all build tools are
# thrown away, so the final image is small and has no build tooling to attack.

### time_manager_frontend/nginx.conf
    server {
      listen 80;
      root /usr/share/nginx/html;
      index index.html;
      location / {
        try_files $uri $uri/ /index.html;   # if the file isn't found, serve index.html
      }
    }
# KEY POINT: vue-router uses "history mode" (clean URLs like /teams). On refresh
# the browser asks nginx for /teams, which is not a real file. try_files sends it
# to index.html, and Vue then shows the right page. Without this, refresh = 404.

### .dockerignore files (time_manager and time_manager_frontend)
# These exclude local build junk (deps, _build, node_modules) from the image,
# so the build is clean and reproducible — the image builds its OWN deps instead
# of copying your Windows/WSL ones, which would break.

================================================================
## 6. LIKELY DOCKER QUESTIONS (short answers)
================================================================

- Image vs container? Image = blueprint; container = a running instance of it.
- Why 3 services? Separation of concerns: database, API, web server each in
  its own container, connected by a private network.
- How do containers find each other? By service name on the compose network
  (the API uses host "db" for Postgres).
- What does depends_on do? Sets start ORDER only. Readiness is handled by the
  pg_isready wait loop in entrypoint.sh.
- What is a volume? Persistent storage. db_data keeps the database even if the
  container is removed.
- Why multi-stage for the front? Build with Node, ship only static files via
  nginx -> small, secure final image.
- Why does nginx need try_files? So vue-router routes still work after a refresh.
- What does "docker compose up --build" do? Rebuild the images from the
  Dockerfiles, then start all the containers.
- Where do the accounts come from in Docker? entrypoint.sh runs seeds.exs on
  startup.

================================================================
## 7. QUICK FIXES (if something breaks during the demo)
================================================================

- "port already in use": another server is still running. Stop it, or in
  Docker run "docker compose down" first.
- Web shows "Could not sign in": the API (mix phx.server) isn't running, or the
  database isn't started (sudo service postgresql start).
- App can't reach API: the API must be running; the app uses 10.0.2.2:4000 on
  the emulator. Keep mix phx.server up.
- Git lock file error: delete .git\index.lock in the repo, then retry.
- Gradle "class file major version" error: JAVA_HOME must point to Java 21.
