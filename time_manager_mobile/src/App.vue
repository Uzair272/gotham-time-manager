<template>
  <div id="app">
    <!-- Sign in / sign up: full-screen brand layout, no bars -->
    <div v-if="isGuestPage" class="guest-layout">
      <div class="brand">
        <div class="logo">
          <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
        </div>
        <h1>Gotham Time</h1>
        <p>Your hours, tracked simply.</p>
      </div>
      <main class="auth-card">
        <router-view :key="$route.fullPath" />
      </main>
    </div>

    <!-- Signed-in layout: top bar + page + bottom tab bar -->
    <div v-else>
      <header class="app-bar">
        <button v-if="showBack" class="icon-btn" @click="$router.back()" aria-label="Back">
          <svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" /></svg>
        </button>
        <h1>{{ title }}</h1>
        <router-link v-if="isLoggedIn" to="/profile" class="avatar">{{ initial }}</router-link>
      </header>

      <!-- Offline banner, pending changes, sync result, fallback spinner -->
      <OfflineBanner />

      <main class="content" :class="{ 'with-tabs': isLoggedIn }">
        <transition name="fade" mode="out-in">
          <!-- The key changes after each sync -> the page reloads fresh server data -->
          <router-view :key="$route.fullPath + '#' + syncCount" />
        </transition>
      </main>

      <!-- v-if: the tab bar doesn't exist at all when logged out -->
      <TabBar v-if="isLoggedIn" />
    </div>
  </div>
</template>

<script>
import auth from "./auth";
import { net } from "./offline";
import TabBar from "./components/TabBar.vue";
import OfflineBanner from "./components/OfflineBanner.vue";

export default {
  name: "App",
  components: { TabBar, OfflineBanner },
  computed: {
    syncCount() {
      return net.syncCount;
    },
    isLoggedIn() {
      return auth.isLoggedIn();
    },
    isGuestPage() {
      return this.$route.meta.access === "guest";
    },
    title() {
      return this.$route.meta.title || "Gotham Time";
    },
    showBack() {
      return Boolean(this.$route.meta.sub);
    },
    initial() {
      const user = auth.state.user;
      return user ? user.username.charAt(0).toUpperCase() : "?";
    },
  },
};
</script>

<style>
/* ===== Theme ===== */
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
  --radius: 16px;
  --shadow: 0 4px 20px rgba(15, 23, 42, 0.08);
  --tab-height: 68px;
}
* {
  box-sizing: border-box;
  -webkit-tap-highlight-color: transparent;
}
body {
  margin: 0;
  font-family: system-ui, -apple-system, Roboto, sans-serif;
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
h2 {
  font-size: 20px;
}

/* ===== Guest layout (sign in / sign up) ===== */
.guest-layout {
  min-height: 100vh;
  padding: 48px 20px 24px;
  background: linear-gradient(160deg, #0f172a 0%, var(--primary) 60%, var(--primary-2) 100%);
}
.brand {
  text-align: center;
  color: #fff;
  margin-bottom: 28px;
}
.brand .logo {
  width: 72px;
  height: 72px;
  margin: 0 auto 12px;
  border-radius: 22px;
  display: grid;
  place-items: center;
  background: rgba(255, 255, 255, 0.15);
  color: var(--accent);
}
.brand .logo svg {
  width: 40px;
  height: 40px;
}
.brand h1 {
  margin: 0;
  font-size: 28px;
}
.brand p {
  margin: 6px 0 0;
  opacity: 0.75;
}
.auth-card {
  background: var(--card);
  border-radius: 24px;
  padding: 8px 20px 20px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
}

/* ===== Top bar ===== */
.app-bar {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  gap: 8px;
  height: 60px;
  padding: 0 16px;
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
  box-shadow: 0 2px 12px rgba(30, 58, 138, 0.3);
}
.app-bar h1 {
  flex: 1;
  margin: 0;
  font-size: 20px;
}
.icon-btn {
  background: none;
  color: #fff;
  padding: 0;
  min-height: 40px;
  width: 40px;
  display: grid;
  place-items: center;
}
.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: var(--accent);
  color: var(--text);
  font-weight: bold;
  text-decoration: none;
}

/* ===== Page content ===== */
.content {
  padding: 16px;
}
.content.with-tabs {
  padding-bottom: calc(var(--tab-height) + 24px);
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s, transform 0.15s;
}
.fade-enter,
.fade-leave-to {
  opacity: 0;
  transform: translateY(6px);
}

/* ===== Reusable pieces ===== */
.card {
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 16px;
}
.pill {
  padding: 4px 10px;
  border-radius: 999px;
  background: #e0e7ff;
  color: var(--primary);
  font-weight: 600;
  font-size: 13px;
}
.section-title {
  margin: 24px 0 10px;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--muted);
}
.empty {
  text-align: center;
  color: var(--muted);
  padding: 32px 0;
}
.fab {
  position: fixed;
  right: 20px;
  bottom: calc(var(--tab-height) + 20px);
  width: 58px;
  height: 58px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, var(--primary), var(--primary-2));
  color: #fff;
  font-size: 32px;
  text-decoration: none;
  box-shadow: 0 8px 20px rgba(30, 58, 138, 0.4);
}

/* ===== Forms (16px text stops Android zooming in on inputs) ===== */
input,
select,
button {
  font-size: 16px;
  font-family: inherit;
}
input,
select {
  width: 100%;
  padding: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fafc;
}
input:focus,
select:focus {
  outline: none;
  border-color: var(--primary-2);
  background: #fff;
}
/* 48px tall = comfortable touch target */
button {
  min-height: 48px;
  padding: 0 18px;
  border: none;
  border-radius: 12px;
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
  font-weight: 600;
}
button:active {
  transform: scale(0.98);
}
button.danger {
  background: var(--red);
  color: #fff;
}
button:disabled {
  opacity: 0.5;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.error {
  color: var(--red);
}
.success {
  color: var(--green);
}
a {
  color: var(--primary-2);
}

/* Wide tables scroll sideways instead of breaking the layout */
table {
  display: block;
  width: 100%;
  overflow-x: auto;
  border-collapse: collapse;
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}
th,
td {
  padding: 12px 10px;
  border-bottom: 1px solid #f1f5f9;
  text-align: left;
  white-space: nowrap;
}
</style>