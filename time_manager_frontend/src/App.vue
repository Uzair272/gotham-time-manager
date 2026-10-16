<template>
  <div id="app">
    <!-- Sign in / sign up: centered branded layout, no navbar -->
    <div v-if="isGuestPage" class="guest-layout">
      <div class="brand">
        <div class="logo">
          <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
        </div>
        <h1>Gotham Time Manager</h1>
        <p>Track working hours at the Gotham town hall.</p>
      </div>
      <div class="auth-card">
        <router-view :key="$route.fullPath" />
      </div>
    </div>

    <!-- Signed-in / public layout: top navbar + page -->
    <div v-else>
      <nav class="main-nav">
        <router-link to="/" class="brand-mini">
          <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
          <span>Gotham Time</span>
        </router-link>

        <!-- v-if (not v-show): hidden links are not even in the page -->
        <div class="links" v-if="isLoggedIn">
          <router-link :to="'/clock/' + userId">Clock</router-link>
          <router-link :to="'/workingTimes/' + userId">Working times</router-link>
          <router-link :to="'/chartManager/' + userId">Charts</router-link>
          <router-link to="/teams">Teams</router-link>
          <router-link v-if="isManagerOrAdmin" to="/users">Users</router-link>
          <router-link to="/profile">Profile</router-link>
        </div>

        <div class="right" v-if="isLoggedIn">
          <span class="who">
            <span class="avatar">{{ initial }}</span>
            {{ username }} <span class="role-badge">{{ role }}</span>
          </span>
          <button class="ghost" @click="logout">Log out</button>
        </div>

        <div class="right" v-else>
          <router-link to="/sign_in">Sign in</router-link>
          <router-link to="/sign_up" class="cta">Sign up</router-link>
        </div>
      </nav>

      <main class="content">
        <router-view :key="$route.fullPath" />
      </main>
    </div>
  </div>
</template>

<script>
import auth from "./auth";

export default {
  name: "App",
  computed: {
    isLoggedIn() {
      return auth.isLoggedIn();
    },
    isGuestPage() {
      return ["/sign_in", "/sign_up"].includes(this.$route.path);
    },
    userId() {
      return auth.state.userId;
    },
    role() {
      return auth.state.role;
    },
    username() {
      return auth.state.user ? auth.state.user.username : "";
    },
    initial() {
      return auth.state.user ? auth.state.user.username.charAt(0).toUpperCase() : "?";
    },
    isManagerOrAdmin() {
      return auth.hasRole("manager", "admin");
    },
  },
  methods: {
    async logout() {
      await auth.signOut();
      this.$router.push("/sign_in");
    },
  },
};
</script>

<style>
/* ===== Theme (global: every page inherits these) ===== */
:root {
  --primary: #1e3a8a;
  --primary-2: #3b82f6;
  --accent: #f5b301;
  --green: #10b981;
  --red: #ef4444;
  --bg: #f1f5f9;
  --card: #ffffff;
  --text: #0f172a;
  --muted: #64748b;
  --radius: 14px;
  --shadow: 0 4px 20px rgba(15, 23, 42, 0.08);
}
* {
  box-sizing: border-box;
}
body {
  margin: 0;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
  background: var(--bg);
  color: var(--text);
}
svg {
  width: 24px;
  height: 24px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}
h1 {
  font-size: 26px;
}
h2 {
  font-size: 22px;
  margin-top: 0;
}
a {
  color: var(--primary-2);
}

/* ===== Top navbar ===== */
.main-nav {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 0 24px;
  height: 62px;
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
  box-shadow: 0 2px 14px rgba(30, 58, 138, 0.3);
}
.brand-mini {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #fff;
  text-decoration: none;
  font-weight: 800;
  font-size: 18px;
}
.brand-mini svg {
  color: var(--accent);
}
.links {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}
.links a {
  color: rgba(255, 255, 255, 0.85);
  text-decoration: none;
  padding: 8px 14px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 15px;
}
.links a:hover {
  background: rgba(255, 255, 255, 0.12);
}
.links a.router-link-active {
  background: #fff;
  color: var(--primary);
}
.right {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 14px;
}
.right a {
  color: #fff;
  text-decoration: none;
  font-weight: 600;
}
.right a.cta {
  background: var(--accent);
  color: var(--text);
  padding: 8px 16px;
  border-radius: 999px;
}
.who {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #fff;
}
.avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: var(--accent);
  color: var(--text);
  font-weight: 800;
}
.role-badge {
  background: rgba(0, 0, 0, 0.25);
  color: #fff;
  border-radius: 999px;
  padding: 2px 10px;
  font-size: 12px;
  text-transform: capitalize;
}
.ghost {
  background: rgba(255, 255, 255, 0.15);
  color: #fff;
}

/* ===== Page content ===== */
.content {
  max-width: 900px;
  margin: 0 auto;
  padding: 28px 24px 48px;
}

/* ===== Guest layout (sign in / sign up) ===== */
.guest-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: linear-gradient(160deg, #0f172a 0%, var(--primary) 60%, var(--primary-2) 100%);
}
.brand {
  text-align: center;
  color: #fff;
  margin-bottom: 24px;
}
.brand .logo {
  width: 76px;
  height: 76px;
  margin: 0 auto 14px;
  border-radius: 22px;
  display: grid;
  place-items: center;
  background: rgba(255, 255, 255, 0.15);
  color: var(--accent);
}
.brand .logo svg {
  width: 42px;
  height: 42px;
}
.brand h1 {
  margin: 0;
}
.brand p {
  margin: 6px 0 0;
  opacity: 0.8;
}
.auth-card {
  width: 100%;
  max-width: 380px;
  background: var(--card);
  border-radius: 20px;
  padding: 28px;
  box-shadow: 0 24px 50px rgba(0, 0, 0, 0.3);
}

/* ===== Cards, forms, tables (used across the pages) ===== */
.card {
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 20px;
  margin-bottom: 16px;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 420px;
}
input,
select {
  width: 100%;
  padding: 12px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
  font-size: 15px;
  font-family: inherit;
}
input:focus,
select:focus {
  outline: none;
  border-color: var(--primary-2);
  background: #fff;
}
button {
  cursor: pointer;
  border: none;
  border-radius: 10px;
  padding: 11px 18px;
  font-size: 15px;
  font-weight: 600;
  font-family: inherit;
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
}
button:hover {
  filter: brightness(1.06);
}
button:disabled {
  opacity: 0.5;
  cursor: default;
}
button.danger {
  background: var(--red);
}
table {
  width: 100%;
  border-collapse: collapse;
  background: var(--card);
  border-radius: var(--radius);
  overflow: hidden;
  box-shadow: var(--shadow);
}
th,
td {
  padding: 12px 14px;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}
th {
  background: #f8fafc;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--muted);
}
.error {
  color: var(--red);
}
.success {
  color: var(--green);
}
</style>
