<template>
  <div class="home">
    <!-- Signed in: dashboard -->
    <div v-if="isLoggedIn">
      <header class="hero">
        <p class="greeting">
          {{ greeting }}, <strong>{{ username }}</strong>
          <span class="role-chip">{{ role }}</span>
        </p>
        <h1>Gotham Time Manager</h1>
        <p class="sub">Track and manage working hours at the Gotham town hall.</p>
      </header>

      <div class="tiles">
        <router-link :to="'/clock/' + userId" class="tile">
          <span class="ic ic-green">
            <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
          </span>
          <span class="t-title">Clock in / out</span>
          <span class="t-sub">Start or end your shift</span>
        </router-link>

        <router-link :to="'/workingTimes/' + userId" class="tile">
          <span class="ic ic-blue">
            <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="17" rx="2" /><path d="M3 9h18M8 2v4M16 2v4" /></svg>
          </span>
          <span class="t-title">Working times</span>
          <span class="t-sub">View and edit your shifts</span>
        </router-link>

        <router-link :to="'/chartManager/' + userId" class="tile">
          <span class="ic ic-purple">
            <svg viewBox="0 0 24 24"><path d="M3 3v18h18" /><path d="M7 15l4-5 3 3 4-6" /></svg>
          </span>
          <span class="t-title">Charts</span>
          <span class="t-sub">See your hours visually</span>
        </router-link>

        <router-link to="/teams" class="tile">
          <span class="ic ic-amber">
            <svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3" /><path d="M2 20c0-3 3-5 7-5s7 2 7 5" /><path d="M17 11a3 3 0 100-6M22 20c0-2-1.5-3.5-4-4.2" /></svg>
          </span>
          <span class="t-title">Teams</span>
          <span class="t-sub">Your teams and members</span>
        </router-link>

        <router-link v-if="isManagerOrAdmin" to="/users" class="tile">
          <span class="ic ic-red">
            <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></svg>
          </span>
          <span class="t-title">Users</span>
          <span class="t-sub">Manage people and roles</span>
        </router-link>

        <router-link to="/profile" class="tile">
          <span class="ic ic-slate">
            <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></svg>
          </span>
          <span class="t-title">Profile</span>
          <span class="t-sub">Your account and password</span>
        </router-link>
      </div>
    </div>

    <!-- Guest -->
    <div v-else class="guest-home">
      <h1>Gotham Time Manager</h1>
      <p class="sub">Track your working hours at the Gotham town hall.</p>
      <div class="guest-actions">
        <router-link to="/sign_in" class="btn-primary">Sign in</router-link>
        <router-link to="/sign_up" class="btn-ghost">Create an account</router-link>
      </div>
    </div>
  </div>
</template>

<script>
import auth from "../auth";

export default {
  name: "HomePage",
  computed: {
    isLoggedIn() {
      return auth.isLoggedIn();
    },
    userId() {
      return auth.state.userId;
    },
    username() {
      return auth.state.user ? auth.state.user.username : "";
    },
    role() {
      return auth.state.role;
    },
    isManagerOrAdmin() {
      return auth.hasRole("manager", "admin");
    },
    greeting() {
      const h = new Date().getHours();
      if (h < 12) return "Good morning";
      if (h < 18) return "Good afternoon";
      return "Good evening";
    },
  },
};
</script>

<style scoped>
.hero {
  margin-bottom: 26px;
}
.greeting {
  margin: 0 0 4px;
  color: var(--muted);
  font-size: 15px;
}
.role-chip {
  background: var(--primary);
  color: #fff;
  border-radius: 999px;
  padding: 2px 10px;
  font-size: 12px;
  text-transform: capitalize;
  margin-left: 6px;
}
.hero h1 {
  margin: 0;
}
.sub {
  color: var(--muted);
  margin: 4px 0 0;
}
.tiles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 16px;
}
.tile {
  display: flex;
  flex-direction: column;
  gap: 4px;
  background: var(--card);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 20px;
  text-decoration: none;
  color: var(--text);
  border: 1px solid transparent;
  transition: transform 0.12s ease, box-shadow 0.12s ease, border-color 0.12s ease;
}
.tile:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.14);
  border-color: var(--primary-2);
}
.ic {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  margin-bottom: 8px;
}
.ic svg {
  width: 26px;
  height: 26px;
  color: #fff;
}
.ic-green { background: linear-gradient(135deg, #10b981, #059669); }
.ic-blue { background: linear-gradient(135deg, #3b82f6, #1e3a8a); }
.ic-purple { background: linear-gradient(135deg, #8b5cf6, #6d28d9); }
.ic-amber { background: linear-gradient(135deg, #f5b301, #d97706); }
.ic-red { background: linear-gradient(135deg, #ef4444, #b91c1c); }
.ic-slate { background: linear-gradient(135deg, #64748b, #334155); }
.t-title {
  font-weight: 700;
  font-size: 17px;
}
.t-sub {
  color: var(--muted);
  font-size: 14px;
}
.guest-home {
  text-align: center;
  padding: 40px 0;
}
.guest-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-top: 20px;
}
.btn-primary,
.btn-ghost {
  text-decoration: none;
  padding: 12px 22px;
  border-radius: 999px;
  font-weight: 700;
}
.btn-primary {
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
}
.btn-ghost {
  background: #fff;
  color: var(--primary);
  box-shadow: var(--shadow);
}
</style>
