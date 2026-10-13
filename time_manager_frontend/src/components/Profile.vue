<template>
  <div>
    <h2>My profile</h2>
    <p v-if="!user">Loading...</p>

    <div v-else>
      <form class="form" @submit.prevent="save">
        <label>Username <input v-model="form.username" required /></label>
        <label>Email <input v-model="form.email" type="email" required /></label>
        <label>Role <input :value="user.role" disabled /></label>

        <p><strong>Change password</strong> (leave empty to keep it)</p>
        <input v-model="form.password" type="password" placeholder="New password" />
        <input v-model="form.confirm" type="password" placeholder="Confirm new password" />

        <button type="submit">Save</button>
        <p v-if="message" class="success">{{ message }}</p>
        <p v-if="error" class="error">{{ error }}</p>
      </form>

      <h3>My teams</h3>
      <p v-if="teams.length === 0">You are not in any team yet.</p>
      <ul>
        <li v-for="team in teams" :key="team.id">
          {{ team.name }}
          <span v-if="team.manager_id === user.id">(you manage it)</span>
          <span v-else-if="team.manager">(manager: {{ team.manager.username }})</span>
        </li>
      </ul>
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
