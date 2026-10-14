# Time Manager — Defence Cheat Sheet

Quick revision for the oral. One section per theme: what it is, the key files,
and the questions examiners ask with short answers you can say out loud.

Seed accounts (from `priv/repo/seeds.exs`):
- `admin@gotham.city` / `Admin1234!`  — admin
- `manager@gotham.city` / `Manager1234!` — manager (manages "City Hall")
- `employee@gotham.city` / `Employee1234!` — employee (member of "City Hall")

How to run everything:
- API (Ubuntu/WSL): `cd time_manager && mix phx.server`  (port 4000)
- Web (PowerShell): `cd time_manager_frontend && npm run serve`  (port 8080)
- Mobile (PowerShell): `cd time_manager_mobile && npx cap run android`
- All at once: `docker compose up --build`

---

## Theme 1 — API (Phoenix / Elixir / PostgreSQL)

**What:** a JSON REST API. Schemas: User, Clock, WorkingTime (+ Role, Team added in T5).

**Key ideas**
- `--no-html --no-assets`: API only, no server-rendered pages.
- Schemas have changesets that **validate** (email format, end > start).
- Associations use `on_delete: :delete_all`: delete a user and their clocks go too.
- A clock has a `time` and a boolean `status` (true = in, false = out).

**Likely questions**
- *Why Elixir/Phoenix?* Runs on the Erlang VM: lightweight processes, great at
  many concurrent connections, fault-tolerant (supervisors restart crashes).
- *What is a changeset?* A pipeline that casts and validates incoming data
  before it touches the database.
- *What is Ecto?* The database layer: schemas, changesets, and a query DSL that
  sends values as bound parameters (so, no SQL injection).

---

## Theme 2 — Web front-end (Vue.js)

**What:** a Vue 2 single-page app talking to the API with axios.

**Key components:** User, WorkingTimes, WorkingTime, ClockManager, ChartManager
(3 chart types via vue-chartjs). Routing with vue-router.

**Likely questions**
- *SPA vs multi-page?* One page; the router swaps components and only data is
  fetched, so navigation is instant and the server sends JSON, not HTML.
- *How does the front reach the API?* One axios instance (`api.js`) with the
  base URL; CORS is enabled on the API so a different port can call it.
- *What is a component?* A reusable, self-contained piece of UI (template +
  logic + style).

---

## Theme 3 — Docker (containerisation)

**What:** the whole stack runs in containers with one command.

**Files:** `docker-compose.yml`, `time_manager/Dockerfile`,
`time_manager_frontend/Dockerfile`, `entrypoint.sh`, `nginx.conf`, `.env`,
`.dockerignore` files.

**How it fits together**
- `docker-compose.yml` defines 3 services: **db** (Postgres), **phoenix** (API),
  **front** (the built Vue app served by nginx). `depends_on` sets start order.
- The API Dockerfile builds an Elixir image, installs deps, compiles.
- `entrypoint.sh` waits for Postgres, runs `ecto.create` + `ecto.migrate`, then
  `seeds.exs` (creates the admin), then starts the server.
- The front Dockerfile is **multi-stage**: build the Vue app with Node, then
  copy the static `dist` into a small nginx image.
- `nginx.conf` sends unknown paths to `index.html` so vue-router works on refresh.
- `.dockerignore` keeps local `deps`, `_build`, `node_modules` out of the image
  so it always builds clean and reproducible.

**Likely questions**
- *Why Docker?* One command gives everyone the exact same environment; no "works
  on my machine".
- *Image vs container?* An image is the blueprint; a container is a running
  instance of it.
- *Why multi-stage for the front?* Build tools stay in the build stage; the final
  image only ships the static files + nginx, so it's small.
- *Why `.dockerignore`?* Local build artifacts (Windows node_modules, WSL deps)
  would overwrite the clean ones and break the build.

---

## Theme 4 — Change resistance / communication

**What:** a non-coding UX subpart. Deliverables in `communication/`.

- **Stakeholder map:** employees, union (CGT-U), managers, administrator, mayor,
  citizens, dev team — each with commitment / needs / worries.
- **3 mockups:** employee, manager, administrator screens matched to each role.
- **3 communication pieces:** employee/union leaflet, manager memo, mayor's
  public statement — each answers a specific worry from the map.

**Likely questions**
- *Why does change meet resistance?* People fear surveillance, extra work, or
  losing control; you counter each worry with honest, targeted communication.
- *Who are the stakeholders and what do they fear?* Employees: being watched.
  Union: workers' rights. Managers: more admin. Be ready to name one worry each.

---

## Theme 5 — Authentication & permissions

**What:** passwords, roles, teams, JWT login, and route protection.

**Key files (API):** `accounts.ex`, `auth/token.ex`, `plugs/authenticate.ex`,
`plugs/require_role.ex`, `auth_controller.ex`, `router.ex`.

**The login flow (be able to draw this)**
1. `POST /sign_in` with email + password.
2. API checks the bcrypt hash; on success generates a random 50-char **XSRF token**.
3. Builds a **JWT** (Joken) holding the xsrf token, user id, role, 30-day expiry.
4. Sends the JWT in an **HttpOnly cookie**; returns the xsrf token + id + role in the body.
5. The front stores xsrf/id/role in **localStorage** (the JWT it cannot read).
6. On every protected request: the cookie is sent automatically, and the front
   adds the xsrf token in the `x-xsrf-token` header. The `Authenticate` plug
   checks the signature, the expiry, and that the header matches the token inside
   the JWT, then loads the user + role.

**Roles:** employee (default), manager, admin — fixed, no CRUD (inserted by the
migration). Permissions: router pipelines for role-only rules; controller checks
(`can_access_user?`) for "whose data is this".

**Likely questions**
- *Why a cookie AND a header?* The HttpOnly cookie protects the JWT from XSS
  (JS can't read it). But cookies are sent automatically, which enables CSRF; the
  header the attacker can't guess defeats CSRF. You need both.
- *401 vs 403?* 401 = not authenticated; 403 = authenticated but not allowed.
- *Is the role read from the JWT?* It's in the JWT, but the plug re-reads the
  user from the DB each request, so a demotion applies immediately.
- *Why bcrypt?* Slow + salted, so stolen hashes can't be brute-forced.
- *Why no CRUD on roles?* Permissions depend on these exact roles; letting them
  be edited would break the checks.

---

## Theme 6 — Mobile app (Capacitor + Vue)

**What:** an Android app reusing the Vue code and the same API, with offline mode.

**Key ideas**
- **Hybrid app:** the Vue app runs in a native WebView; Capacitor plugins give
  access to native features. `npm run build` → `npx cap sync` → runs on Android.
- **Navigation:** a bottom **tab bar** (not a burger menu), easier on the thumb.
- **API on the emulator:** `10.0.2.2` is the emulator's alias for the PC's
  localhost. Native HTTP (Capacitor) handles the cookie (no CORS, no WebView
  cookie block).

**Offline mode (the core — be able to explain)**
- **Cache:** a LokiJS NoSQL DB on the phone stores every API answer (one doc per
  URL, no duplicates). Online, the server has priority: API first, then cache
  updated. Offline, pages read from the cache.
- **Queue:** changes made offline go into a **FIFO list** in localStorage (as
  JSON strings). A clock action stores the **real time of the tap** and the
  expected status.
- **Sync:** back online, a native spinner shows while the queue is sent
  oldest-first. If the server refuses one (conflict), the queue is cancelled and
  the cache reloaded from the server — server wins.

**Native features:** network status, dialogs (confirm + prompt for new team),
haptics, toasts, status bar, OS date picker, adaptive icon + splash, native sync
spinner.

**Likely questions**
- *How can clock in/out work offline?* The request is queued with the tap's real
  time; replayed in order on reconnect, so the server records the right time.
- *Why FIFO?* Clock in then clock out depend on order.
- *What if the website changed the data first?* Server is the source of truth;
  the queued clock carries the expected status, so the API detects the conflict,
  refuses it, and the app reloads server data.
- *Why LokiJS + localStorage?* LokiJS = lightweight NoSQL cache; localStorage
  only stores strings, hence JSON.stringify for the queue.
- *Why can't the password change offline?* The queue sits in clear text on the
  phone; a password must never be stored like that.

---

## Theme 7 — Security

**What:** audit the app for flaws and patch them. Full write-up in `SECURITY.md`.

**Already safe:** SQL injection (Ecto params), XSS (Vue escaping), bcrypt hashes,
no clear-text passwords, JWT HttpOnly, CSRF (xsrf header), role-based routes.

**Patched in this theme**
- **Brute-force:** rate-limit plug, 5 sign-in/sign-up attempts per IP per minute
  (6th → 429). In-memory ETS counter; fails open.
- **DoS:** 1 MB request-body limit + `limit(500)` on list queries.
- **Headers:** `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: no-referrer`.
- **HTTPS:** `force_ssl` + HSTS in the production config.

**Tools (bootstrap):** dirb (hidden routes), nmap (open ports), sqlmap (SQL
injection), John the Ripper (crack weak hashes), Nikto (server scan).

**Likely questions**
- *Three questions for any flaw?* What is it? How do you detect it? How do you
  protect against it?
- *Demo the rate limiter:* 6 wrong sign-ins in Postman → the 6th returns 429.
- *Weak vs strong hash?* MD5 (fast, 32 hex chars) breaks instantly; bcrypt is
  slow and salted.
- *How would you secure the mobile app further?* OS secure storage for the
  cache, certificate pinning.

---

## General questions about the whole project

- *Walk us through the architecture.* Postgres ← Ecto ← Phoenix API (JSON) ←
  HTTP → Vue web app and the Capacitor mobile app. All share the same API.
- *What was the hardest part?* (Pick one you actually did — e.g. the offline
  FIFO sync, or the JWT + XSRF flow.)
- *What would you improve with more time?* Automated tests, pagination on all
  lists, push notifications, cert pinning on mobile.
