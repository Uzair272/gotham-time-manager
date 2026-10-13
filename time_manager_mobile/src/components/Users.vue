<template>
  <div>
    <p v-if="error" class="error">{{ error }}</p>
    <p v-if="!net.online" class="offline-note">
      Offline: you can read the list, but changes need a connection.
    </p>

    <!-- One card per user -->
    <div v-for="u in users" :key="u.id" class="user-card card">
      <div class="row">
        <div class="avatar-sm">{{ u.username.charAt(0).toUpperCase() }}</div>
        <div class="who">
          <strong>
            {{ u.username }}
            <span v-if="u.id === myId" class="me">(you)</span>
          </strong>
          <span>{{ u.email }}</span>
        </div>

        <!-- Only an admin can promote / demote (and not themself) -->
        <select
          v-if="isAdmin && u.id !== myId"
          class="role-select"
          :value="u.role"
          :disabled="!net.online"
          @change="changeRole(u, $event.target.value)"
        >
          <option v-for="r in roles" :key="r.id" :value="r.name">{{ r.name }}</option>
        </select>
        <span v-else class="pill">{{ u.role }}</span>
      </div>

      <div v-if="canSeeData(u) || (isAdmin && u.id !== myId)" class="actions">
        <!-- A manager only sees the data of their team members -->
        <router-link v-if="canSeeData(u)" :to="'/workingTimes/' + u.id" class="chip-link">
          Times
        </router-link>
        <router-link v-if="canSeeData(u)" :to="'/clock/' + u.id" class="chip-link">
          Clock
        </router-link>
        <button
          v-if="isAdmin && u.id !== myId"
          class="danger small"
          :disabled="!net.online"
          @click="deleteUser(u)"
        >
          Delete
        </button>
      </div>
    </div>

    <!-- Admin: create a user -->
    <div v-if="isAdmin">
      <h3 class="section-title">Create a user</h3>
      <form class="form card" @submit.prevent="createUser">
        <input v-model="newUser.username" placeholder="Username" required />
        <input v-model="newUser.email" type="email" placeholder="Email" required />
        <input v-model="newUser.password" type="password" placeholder="Password (8+)" required />
        <button type="submit" :disabled="!net.online">Create</button>
      </form>
    </div>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";
import { cachedGet, net } from "../offline";
import { confirmDialog, toast, vibrate } from "../native";

export default {
  name: "UsersPage",
  data() {
    return {
      net,
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
    // Reading works offline (cache); writing needs the API
    async load() {
      try {
        const [users, roles, teams] = await Promise.all([
          cachedGet("/users"),
          cachedGet("/roles"),
          cachedGet("/teams"),
        ]);
        this.users = users.data.data;
        this.roles = roles.data.data;
        // Members of the teams I manage (a manager can only see their data)
        this.memberIds = teams.data.data
          .filter((t) => t.manager_id === this.myId)
          .flatMap((t) => t.members.map((m) => m.id));
        this.error = "";
      } catch (err) {
        this.error = "No saved data yet. Connect once to load the users.";
      }
    },
    canSeeData(u) {
      return this.isAdmin || u.id === this.myId || this.memberIds.includes(u.id);
    },
    async changeRole(user, role) {
      this.error = "";
      try {
        await api.put(`/users/${user.id}/role`, { role });
        vibrate();
        toast(`${user.username} is now ${role}`);
      } catch (err) {
        this.error = (err.response && err.response.data.error) || "Could not change the role.";
      }
      this.load();
    },
    async deleteUser(user) {
      // Native confirm dialog
      const ok = await confirmDialog(
        "Delete user",
        `Delete ${user.username}? This cannot be undone.`,
        "Delete"
      );
      if (!ok) return;
      try {
        await api.delete(`/users/${user.id}`);
        vibrate();
        toast(`${user.username} deleted`);
      } catch (err) {
        this.error = "Could not delete the user.";
      }
      this.load();
    },
    async createUser() {
      this.error = "";
      try {
        await api.post("/users", this.newUser);
        toast(`${this.newUser.username} created`);
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
.offline-note {
  margin: 0 0 12px;
  padding: 10px 12px;
  border-radius: 12px;
  background: #fef3c7;
  color: #92400e;
  font-size: 14px;
}
.user-card {
  margin-bottom: 10px;
}
.row {
  display: flex;
  align-items: center;
  gap: 12px;
}
.avatar-sm {
  flex-shrink: 0;
  width: 42px;
  height: 42px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, var(--primary), var(--primary-2));
  color: #fff;
  font-weight: 800;
}
.who {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.who span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: var(--muted);
  font-size: 14px;
}
.me {
  color: var(--muted);
  font-weight: normal;
}
.role-select {
  width: auto;
  padding: 8px;
  font-size: 14px;
}
.actions {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
}
.chip-link {
  padding: 8px 14px;
  border-radius: 999px;
  background: #e0e7ff;
  color: var(--primary);
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
}
.small {
  min-height: 36px;
  margin-left: auto;
  font-size: 14px;
}
</style>