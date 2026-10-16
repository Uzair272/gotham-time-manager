<template>
  <div>
    <h2>My profile</h2>
    <p v-if="!user" class="card">Loading...</p>

    <div v-else>
      <div class="card">
        <form class="form" @submit.prevent="save">
          <label>Username <input v-model="form.username" required /></label>
          <label>Email <input v-model="form.email" type="email" required /></label>
          <label>Role <input :value="user.role" disabled /></label>

          <p class="section-label"><strong>Change password</strong> (leave empty to keep it)</p>
          <input v-model="form.password" type="password" placeholder="New password" />
          <input v-model="form.confirm" type="password" placeholder="Confirm new password" />

          <button type="submit">Save</button>
          <p v-if="message" class="success">{{ message }}</p>
          <p v-if="error" class="error">{{ error }}</p>
        </form>
      </div>

      <div class="card">
        <h3>My teams</h3>
        <p v-if="teams.length === 0" class="muted">You are not in any team yet.</p>
        <ul class="team-list">
          <li v-for="team in teams" :key="team.id">
            <strong>{{ team.name }}</strong>
            <span v-if="team.manager_id === user.id" class="tag you">you manage it</span>
            <span v-else-if="team.manager" class="tag">manager: {{ team.manager.username }}</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";

export default {
  name: "ProfilePage",
  data() {
    return {
      user: null,
      teams: [],
      form: { username: "", email: "", password: "", confirm: "" },
      message: "",
      error: "",
    };
  },
  async created() {
    try {
      this.user = await auth.refresh();
      this.form.username = this.user.username;
      this.form.email = this.user.email;
      const { data } = await api.get("/teams");
      this.teams = data.data;
    } catch (err) {
      this.error = "Could not load your profile.";
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
      const body = { username: this.form.username, email: this.form.email };
      if (this.form.password) {
        body.password = this.form.password;
      }
      try {
        await api.put(`/users/${this.user.id}`, body);
        this.user = await auth.refresh();
        this.form.password = "";
        this.form.confirm = "";
        this.message = "Profile saved.";
      } catch (err) {
        const errors = err.response && err.response.data && err.response.data.errors;
        this.error = errors ? JSON.stringify(errors) : "Could not save.";
      }
    },
  },
};
</script>

<style scoped>
.form label {
  font-weight: 600;
  font-size: 14px;
}
.section-label {
  margin: 8px 0 0;
}
.team-list {
  list-style: none;
  padding: 0;
  margin: 0;
}
.team-list li {
  padding: 10px 0;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  gap: 10px;
}
.tag {
  background: #f1f5f9;
  color: var(--muted);
  border-radius: 999px;
  padding: 2px 10px;
  font-size: 12px;
  font-weight: 600;
}
.tag.you {
  background: rgba(16, 185, 129, 0.14);
  color: #059669;
}
.muted {
  color: var(--muted);
}
</style>
