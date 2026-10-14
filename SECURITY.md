# Time Manager — Security Report (Theme 07)

Penetration test and hardening of the Time Manager application
(Phoenix/Elixir API + Vue.js web front-end + Capacitor mobile app).

For every attack vector we answer the three questions from the brief:
**What is the flaw? How do you detect it? How do you protect against it?**

---

## Summary

| # | Attack vector | Status | Protection |
|---|---------------|--------|------------|
| 1 | SQL / NoSQL injection | Protected | Parameterized queries (Ecto) |
| 2 | XSS / HTML / script injection | Protected | Vue auto-escaping; no user data in `v-html` |
| 3 | Password hashes | Protected | bcrypt, cost 12, random salt |
| 4 | Passwords in clear text | Protected | Never stored or returned; hashed before save |
| 5 | JWT http-only | Protected | JWT in an HttpOnly cookie |
| 6 | CSRF | Protected | XSRF token checked against the JWT on every request |
| 7 | Routes / endpoints for unauthorized users | Protected | Auth plug + role pipelines (401 / 403) |
| 8 | Brute-force on login | **Patched** | Rate limiting (5 / IP / minute) |
| 9 | Denial of service (fill DB / huge payload) | **Patched** | Body-size limit + capped list queries |
| 10 | Clickjacking / MIME sniffing | **Patched** | Security headers |
| 11 | HTTPS only | By deployment | `force_ssl` + HSTS enabled in production config |
| 12 | Accessible configuration files | Protected | Secrets from env vars in prod; `.env`, `_build`, `deps` git/docker-ignored |

"Protected" = already safe by design. "Patched" = a gap we found and fixed during this audit.

---

## 1. SQL / NoSQL injection

- **Flaw:** user input concatenated into a query lets an attacker inject SQL,
  e.g. `email = "' OR 1=1 --"` to bypass a check or dump the database.
- **Detection:** add a quote to an input (`id=73'`) and watch for a database
  error; or run `sqlmap` against a parameterized URL.
- **Protection:** we never build SQL by hand. Every query goes through Ecto,
  which sends values as **bound parameters** (`WHERE email = $1`), so input is
  always data, never code. Example — `Accounts.authenticate/2`:
  `where([u], fragment("lower(?)", u.email) == ^String.downcase(email))`.
  The `^` pins the value as a parameter.

## 2. XSS / HTML / script injection

- **Flaw:** user-supplied text rendered as HTML runs attacker JavaScript,
  e.g. a username of `<script>steal()</script>`.
- **Detection:** submit `<script>alert(1)</script>` in a field and see if it executes.
- **Protection:** Vue escapes everything in `{{ }}` by default, so user data is
  shown as text. The only `v-html` in the project (the mobile tab bar icons)
  binds a **hard-coded developer constant**, never user input, so it cannot be
  an injection point. The API also returns JSON, not HTML.

## 3. Password hashes

- **Flaw:** fast or unsalted hashes (MD5, SHA-1) are broken in seconds with a
  tool like John the Ripper or a rainbow table.
- **Detection:** inspect a stored hash; a 32-hex-char value is MD5 (weak).
- **Protection:** passwords are hashed with **bcrypt** (`bcrypt_elixir`), cost
  factor 12, with a random per-password salt. Bcrypt is deliberately slow, so
  brute-forcing a stolen hash is impractical. A stored value looks like
  `$2b$12$...` — algorithm, cost, salt and hash.

## 4. Passwords in clear text

- **Flaw:** passwords stored or returned in plain text leak on any DB dump or
  API response.
- **Detection:** read the users table or a sign-in response and look for the
  plain password.
- **Protection:** the plain password lives only in memory during the request
  (a `virtual` field), is hashed before insert, and is `redact: true` so it
  never appears in logs. No endpoint ever returns it.

## 5. JWT http-only

- **Flaw:** a JWT in `localStorage` is readable by JavaScript, so an XSS bug
  lets an attacker steal the session token.
- **Detection:** open DevTools and try `localStorage` / `document.cookie`; if
  the token is there, it is stealable.
- **Protection:** the JWT is sent in an **HttpOnly cookie**
  (`put_resp_cookie(..., http_only: true)`), which JavaScript cannot read.
  Only the non-sensitive XSRF token, user id and role are kept in localStorage.

## 6. CSRF (cross-site request forgery)

- **Flaw:** because the browser sends the JWT cookie automatically, a malicious
  site could trigger a request to our API using the victim's session.
- **Detection:** make a cross-origin request with the cookie but no custom
  header and see if it succeeds.
- **Protection:** every protected request must also carry the XSRF token in the
  `x-xsrf-token` header; the `Authenticate` plug checks it matches the token
  embedded in the JWT. A malicious site cannot read that token, so forged
  requests are rejected (401).

## 7. Routes / endpoints accessible by unauthorized users

- **Flaw:** sensitive routes reachable without the right identity or role, e.g.
  an employee deleting another user, or reading someone else's clocks.
- **Detection:** call protected endpoints with no token, a wrong role, or
  another user's id (tested in Postman).
- **Protection:** three layers —
  1. `Authenticate` plug: no valid JWT + XSRF → **401**.
  2. `RequireRole` pipelines in the router: wrong role → **403**
     (`/users` manager+admin; create/delete/role-change admin only).
  3. Per-record checks in controllers (`can_access_user?/2`,
     `can_manage_team?/2`): you can only touch data you own or manage.
  401 = "I don't know who you are"; 403 = "I know you, but you may not".

## 8. Brute-force on login  *(patched)*

- **Flaw:** unlimited sign-in attempts let an attacker try passwords endlessly.
- **Detection:** script many `POST /users/sign_in` with different passwords and
  see that all are processed.
- **Protection:** a rate-limit plug (`RateLimit`) backed by an in-memory ETS
  counter allows **5 attempts per IP per minute** on `sign_in` and `sign_up`;
  the 6th returns **429 Too Many Requests**. The limiter fails open, so a fault
  in it never blocks legitimate users.

## 9. Denial of service — fill the DB / huge payload  *(patched)*

- **Flaw:** a giant request body, or an endpoint that returns an unbounded
  number of rows, can exhaust server memory and crash page rendering.
- **Detection:** POST a very large JSON body; or insert thousands of clocks and
  load the list.
- **Protection:**
  - `Plug.Parsers` rejects any request body over **1 MB** (`length: 1_000_000`).
  - List queries are capped (`limit(500)` on the clocks list), so the response
    size is bounded no matter how big the table grows.

## 10. Clickjacking / MIME sniffing  *(patched)*

- **Flaw:** the site embedded in a hidden iframe (clickjacking), or the browser
  guessing a response's type and running it as script (MIME sniffing).
- **Detection:** check the response headers; missing `X-Frame-Options` /
  `X-Content-Type-Options` means exposed.
- **Protection:** a `SecurityHeaders` plug adds `X-Frame-Options: DENY`,
  `X-Content-Type-Options: nosniff` and `Referrer-Policy: no-referrer` to every
  response.

## 11. HTTPS only

- **Flaw:** plain HTTP lets a man-in-the-middle read or change requests,
  including the cookie and XSRF token.
- **Detection:** intercept traffic on an open network; HTTP is readable.
- **Protection:** in production the endpoint enables `force_ssl` with HSTS, so
  all traffic is redirected to HTTPS and browsers refuse plain HTTP afterwards.
  (Development uses HTTP locally for convenience only.)

## 12. Accessible configuration files

- **Flaw:** secrets in the repo or served publicly (e.g. a readable `.env`,
  a hard-coded production secret) hand an attacker the keys.
- **Detection:** tools like `dirb` probe for `/config`, `.env`, `.git` etc.
- **Protection:** production secrets (`SECRET_KEY_BASE`, `JWT_SECRET`,
  `DATABASE_URL`) are read from **environment variables** at runtime, never
  committed. Build artifacts and local env files are excluded via `.gitignore`
  and `.dockerignore`. The API serves only JSON, not a browsable file tree.

---

## And the mobile app?

- The mobile app uses the **same API**, so every server-side protection above
  applies to it unchanged.
- The JWT is held by the native cookie manager (Capacitor Http), not by
  JavaScript — the mobile equivalent of HttpOnly.
- The offline queue never stores a password: a password change is refused while
  offline, so no secret is written to the device in clear.
- Remaining risk: a stolen/rooted device could read the local cache. Mitigation
  for production would be OS secure storage and certificate pinning.

---

## Tools referenced (bootstrap)

- **dirb / gobuster** — scan for hidden routes and config files.
- **nmap** — discover open ports and service versions on a host.
- **sqlmap** — automate testing a URL parameter for SQL injection.
- **John the Ripper** — crack weak password hashes (demonstrates why bcrypt).
- **Nikto** — scan a web server for known-dangerous files and misconfigurations.
