<template>
  <div>
    <h2>Users</h2>
    <p v-if="error" class="error">{{ error }}</p>

    <table v-if="users.length">
      <thead>
        <tr>
          <th>Id</th>
          <th>Username</th>
          <th>Email</th>
          <th>Role</th>
          <th>Data</th>
          <th v-if="isAdmin">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="u in users" :key="u.id">
          <td>{{ u.id }}</td>
          <td>{{ u.username }}</td>
          <td>{{ u.email }}</td>
          <td>
            <!-- Only an admin can promote / demote (and not themself) -->
            <select
              v-if="isAdmin && u.id !== myId"
              :value="u.role"
              @change="changeRole(u, $event.target.value)"
            >
              <option v-for="r in roles" :key="r.id" :value="r.name">{{ r.name }}</option>
            </select>
            <span v-else>{{ u.role }}</span>
          </td>
          <td>
            <template v-if="canSeeData(u)">
              <router-link :to="'/workingTimes/' + u.id">Times</router-link> |
              <router-link :to="'/clock/' + u.id">Clock</router-link> |
              <router-link :to="'/chartManager/' + u.id">Charts</router-link>
            </template>
            <span v-else class="muted">not in your teams</span>
          </td>
          <td v-if="isAdmin">
            <button v-if="u.id !== myId" @click="deleteUser(u)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="isAdmin">
      <h3>Create a user</h3>
      <form class="form" @submit.prevent="createUser">
        <input v-model="newUser.username" placeholder="Username" required />
        <input v-model="newUser.email" type="email" placeholder="Email" required />
        <input v-model="newUser.password" type="password" placeholder="Password (8+)" required />
        <button type="submit">Create</button>
      </form>
    </div>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";

export default {
  name: "UsersPage",
  data() {
    return {
      users: [],
      roles: [],
      memberIds: [],
      newUser: { username: "", email: "", password: "" },
      error: "",
    };
  },
  computed: {
    isAdmin() {
      return auth.hasRole("admin");
    },
    myId() {
      return auth.state.userId;
    },
  },
  created() {
    this.load();
  },
  methods: {
    async load() {
      try {
        const [users, roles, teams] = await Promise.all([
          api.get("/users"),
          api.get("/roles"),
          api.get("/teams"),
        ]);
        this.users = users.data.data;
        this.roles = roles.data.data;
        // Members of the teams I manage (a manager can only see their data)
        this.memberIds = teams.data.data
          .filter((t) => t.manager_id === this.myId)
          .flatMap((t) => t.members.map((m) => m.id));
      } catch (err) {
        this.error = "Could not load users.";
      }
    },
    canSeeData(u) {
      return this.isAdmin || u.id === this.myId || this.memberIds.includes(u.id);
    },
    async changeRole(user, role) {
      this.error = "";
      try {
        await api.put(`/users/${user.id}/role`, { role });
      } catch (err) {
        this.error = (err.response && err.response.data.error) || "Could not change the role.";
      }
      this.load();
    },
    async deleteUser(user) {
      if (!window.confirm(`Delete ${user.username}?`)) return;
      try {
        await api.delete(`/users/${user.id}`);
      } catch (err) {
        this.error = "Could not delete the user.";
      }
      this.load();
    },
    async createUser() {
      this.error = "";
      try {
        await api.post("/users", this.newUser);
        this.newUser = { username: "", email: "", password: "" };
        this.load();
      } catch (err) {
        const errors = err.response && err.response.data && err.response.data.errors;
        this.error = errors ? JSON.stringify(errors) : "Could not create the user.";
      }
    },
  },
};
</script>

<style scoped>
.muted {
  color: #999;
}
</style>
