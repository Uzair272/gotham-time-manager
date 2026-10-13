<template>
  <div>
    <p v-if="!user && !error" class="empty">Loading...</p>
    <p v-if="error && !user" class="error">{{ error }}</p>

    <div v-if="user">
      <!-- Header -->
      <div class="profile-head card">
        <div class="big-avatar">{{ user.username.charAt(0).toUpperCase() }}</div>
        <div>
          <h2>{{ user.username }}</h2>
          <p>{{ user.email }}</p>
          <span class="pill">{{ user.role }}</span>
        </div>
      </div>

      <!-- Edit form -->
      <h3 class="section-title">Account</h3>
      <form class="form card" @submit.prevent="save">
        <label>
          Username
          <input v-model="form.username" required />
        </label>
        <label>
          Email
          <input v-model="form.email" type="email" required />
        </label>

        <p class="hint">Change password (leave empty to keep it)</p>
        <input v-model="form.password" type="password" placeholder="New password" />
        <input v-model="form.confirm" type="password" placeholder="Confirm new password" />

        <button type="submit" :disabled="saving">Save changes</button>
        <p v-if="message" class="success">{{ message }}</p>
        <p v-if="error" class="error">{{ error }}</p>
      </form>

      <!-- Teams -->
      <h3 class="section-title">My teams</h3>
      <div class="card">
        <p v-if="teams.length === 0" class="muted">You are not in any team yet.</p>
        <div v-for="team in teams" :key="team.id" class="team-row">
          <strong>{{ team.name }}</strong>
          <span v-if="team.manager_id === user.id" class="pill">You manage it</span>
          <span v-else-if="team.manager" class="muted">Manager: {{ team.manager.username }}</span>
        </div>
      </div>

      <!-- Log out (on mobile it lives here instead of a navbar) -->
      <button class="danger logout" @click="logout">Log out</button>
    </div>
  </div>
</template>

<script>
import auth from "../auth";
import { cachedGet, cacheSet, send, net } from "../offline";
import { confirmDialog, toast } from "../native";

export default {
  name: "ProfilePage",
  data() {
    return {
      user: null,
      teams: [],
      form: { username: "", email: "", password: "", confirm: "" },
      message: "",
      error: "",
      saving: false,
    };
  },
  async created() {
    try {
      // Online: from the API. Offline: from the cache.
      this.user = await auth.refresh();
      this.form.username = this.user.username;
      this.form.email = this.user.email;
      const { data } = await cachedGet("/teams");
      this.teams = data.data;
    } catch (err) {
      this.error = "No saved data yet. Connect once to load your profile.";
    }
  },
  methods: {
    async save() {
      this.message = "";
      this.error = "";
      if (this.form.password && this.form.password !== this.form.confirm) {
        this.error = "The two passwords are different.";
        return;
      }
      // Security: never store a password in the offline queue (plain text on the phone)
      if (this.form.password && !net.online) {
        this.error = "You can only change your password when online.";
        return;
      }

      const body = { username: this.form.username, email: this.form.email };
      if (this.form.password) {
        body.password = this.form.password;
      }

      this.saving = true;
      try {
        const result = await send("put", `/users/${this.user.id}`, body, async () => {
          // Offline: update the saved copy so the change shows immediately
          const updated = { ...this.user, username: body.username, email: body.email };
          await cacheSet("/users/me", { data: updated });
        });
        this.user = await auth.refresh();
        this.form.password = "";
        this.form.confirm = "";
        this.message = result.queued
          ? "Saved offline. It will sync when you're back online."
          : "Profile saved.";
        toast(this.message); // native toast
      } catch (err) {
        const errors = err.response && err.response.data && err.response.data.errors;
        this.error = errors
          ? Object.entries(errors)
              .map(([field, messages]) => `${field} ${messages.join(", ")}`)
              .join(" / ")
          : "Could not save.";
      } finally {
        this.saving = false;
      }
    },
    async logout() {
      // Native confirm dialog
      const ok = await confirmDialog("Log out", "Do you want to log out?", "Log out");
      if (!ok) return;
      await auth.signOut();
      this.$router.push("/sign_in");
    },
  },
};
</script>

<style scoped>
.profile-head {
  display: flex;
  align-items: center;
  gap: 16px;
}
.profile-head h2 {
  margin: 0;
}
.profile-head p {
  margin: 2px 0 8px;
  color: var(--muted);
  font-size: 14px;
}
.big-avatar {
  flex-shrink: 0;
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, var(--primary), var(--primary-2));
  color: #fff;
  font-size: 28px;
  font-weight: 800;
}
label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
  color: var(--muted);
}
.hint {
  margin: 8px 0 0;
  font-size: 14px;
  color: var(--muted);
}
.team-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 10px 0;
  border-bottom: 1px solid #f1f5f9;
}
.team-row:last-child {
  border-bottom: none;
}
.muted {
  color: var(--muted);
  font-size: 14px;
  margin: 0;
}
.logout {
  width: 100%;
  margin-top: 28px;
}
</style>