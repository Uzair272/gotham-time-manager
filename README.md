# Gotham Time Manager

A full-stack, multi-platform **time-tracking application** for the Gotham town hall: employees clock in and out, managers oversee their teams, and administrators manage the whole organisation. Built as a 7-theme engineering project covering a REST API, a single-page web app, a native mobile app with offline support, authentication & role-based access control, and a security audit.

> **Stack:** Elixir · Phoenix · Ecto · PostgreSQL · Vue.js · Capacitor (Android) · Docker

---

## Features

- **Clock in / out** with per-second working-time tracking (stored in UTC, shown in local time).
- **Working times & dashboards** — per-user shift history with bar, line, and pie charts (Chart.js).
- **Teams** — managers oversee their team members; admins manage everyone.
- **Authentication & roles** — three roles (employee, manager, admin) with bcrypt-hashed passwords, JWT in an HttpOnly cookie, and an XSRF token.
- **Role-based access control** — enforced at two layers: router pipelines (401 / 403) and per-record checks.
- **Native Android app** (Capacitor) with **full offline mode** — reads served from a local LokiJS cache, writes queued FIFO in storage and synced when back online (server-wins conflict resolution), plus native haptics, dialogs, toasts, and status bar.
- **Security hardening** — rate limiting (429), request-size & query caps (anti-DoS), SQL-injection prevention via parameterised queries, XSS-safe rendering, security headers, and forced HTTPS/HSTS in production.
- **Fully dockerised** — database, API, and frontend start with a single `docker compose up`.

---

## Architecture

```
┌──────────────┐     HTTPS / JSON      ┌──────────────────┐        ┌──────────────┐
│  Vue SPA     │  ───────────────────► │  Phoenix API      │ ─────► │ PostgreSQL   │
│  (web)       │   cookie + x-xsrf     │  (Elixir / Ecto)  │  Ecto  │              │
├──────────────┤                       │                   │        └──────────────┘
│ Capacitor    │  offline queue +      │  JWT auth · RBAC  │
│  (Android)   │  LokiJS cache + sync  │  rate limiting    │
└──────────────┘                       └──────────────────┘
```

| Layer | Folder | Tech |
|-------|--------|------|
| Backend API | `time_manager/` | Elixir, Phoenix, Ecto, PostgreSQL |
| Web frontend | `time_manager_frontend/` | Vue.js, vue-router, axios, Chart.js |
| Mobile app | `time_manager_mobile/` | Vue + Capacitor (Android), LokiJS |
| Infra | `docker-compose.yml` | Docker (Postgres + API + nginx) |

---

## Run it

### With Docker (recommended)

```bash
docker compose up --build          # starts Postgres + Phoenix API + Vue frontend
docker compose exec phoenix mix ecto.setup   # create tables + seed demo accounts
```

- Web app: http://localhost:8080
- API: http://localhost:4000/api

### Demo accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@gotham.city | Admin1234! |
| Manager | manager@gotham.city | Manager1234! |
| Employee | employee@gotham.city | Employee1234! |

### Mobile app (Android)

```bash
cd time_manager_mobile
npm install
npm run build && npx cap sync android
npx cap run android      # on an emulator; the API is reached at 10.0.2.2:4000
```

---

## Security

Threats addressed and how — brute-force (rate limiting → 429), DoS (1 MB body cap, 500-row query cap), SQL injection (Ecto parameterised queries), XSS (Vue auto-escaping), clickjacking (`X-Frame-Options: DENY`), and traffic interception (`force_ssl` / HSTS in production). See [`SECURITY.md`](SECURITY.md) for the full audit.

---

## Tech highlights

- **Two-layer authorization:** router role pipelines decide *route* access, context functions (`can_access_user?`) decide *record* access.
- **Honest offline timestamps:** the mobile app records the real tap time even while offline, so synced clocks are accurate.
- **Timing-safe auth:** `Bcrypt.no_user_verify/0` keeps wrong-email and wrong-password logins indistinguishable.

---

*Built with Elixir, Phoenix, Vue, Capacitor, and Docker.*
