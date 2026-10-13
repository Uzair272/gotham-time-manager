<template>
  <div>
    <p v-if="error" class="error">{{ error }}</p>
    <p v-if="!net.online" class="offline-note">
      Offline: you can read your teams, but changes need a connection.
    </p>
    <p v-if="!loading && teams.length === 0 && !error" class="empty">No team to show.</p>

    <!-- One card per team -->
    <div v-for="team in teams" :key="team.id" class="team card">
      <div class="team-head">
        <h3>{{ team.name }}</h3>
        <button
          v-if="isAdmin"
          class="danger small"
          :disabled="!net.online"
          @click="deleteTeam(team)"
        >
          Delete
        </button>
      </div>

      <!-- Manager -->
      <div class="manager">
        <span class="label">Manager</span>
        <select
          v-if="isAdmin"
          :value="team.manager_id"
          :disabled="!net.online"
          @change="setManager(team, $event.target.value)"
        >
          <option :value="null">(none)</option>
          <option v-for="m in managers" :key="m.id" :value="m.id">{{ m.username }}</option>
        </select>
        <strong v-else>{{ team.manager ? team.manager.username : "none" }}</strong>
      </div>

      <!-- Members -->
      <span class="label">Members ({{ team.members.length }})</span>
      <div v-for="member in team.members" :key="member.id" class="member">
        <div class="avatar-sm">{{ member.username.charAt(0).toUpperCase() }}</div>
        <div class="who">
          <strong>{{ member.username }}</strong>
          <span>{{ member.email }}</span>
        </div>
        <button
          v-if="canManage(team)"
          class="remove"
          :disabled="!net.online"
          @click="removeMember(team, member)"
          aria-label="Remove"
        >
          ✕
        </button>
      </div>
      <p v-if="team.members.length === 0" class="muted">No members yet.</p>

      <!-- Add a member: only the admin or this team's manager -->
      <div v-if="canManage(team)" class="add-row">
        <select v-model="toAdd[team.id]" :disabled="!net.online">
          <option disabled value="">Add someone...</option>
          <option v-for="u in notMembers(team)" :key="u.id" :value="u.id">
            {{ u.username }} ({{ u.role }})
          </option>
        </select>
        <button :disabled="!toAdd[team.id] || !net.online" @click="addMember(team)">Add</button>
      </div>
    </div>

    <!-- Admin: create a team with a native prompt dialog -->
    <button v-if="isAdmin" class="new-team" :disabled="!net.online" @click="createTeam">
      + New team
    </button>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";
import { cachedGet, net } from "../offline";
import { confirmDialog, promptDialog, toast, vibrate } from "../native";

export default {
  name: "TeamsPage",
  data() {
    return {
      net,
      teams: [],
      users: [],
      toAdd: {},
      error: "",
      loading: true,
    };
  },
  computed: {
    isAdmin() {
      return auth.hasRole("admin");
    },
    managers() {
      return this.users.filter((u) => u.role === "manager" || u.role === "admin");
    },
  },
  created() {
    this.load();
  },
  methods: {
    // Reading works offline (cache); writing needs the API
    async load() {
      this.loading = true;
      try {
        const { data } = await cachedGet("/teams");
        this.teams = data.data;
        // Only managers and admins can list users (to add them to a team)
        if (auth.hasRole("manager", "admin")) {
          const users = await cachedGet("/users");
          this.users = users.data.data;
        }
        this.error = "";
      } catch (err) {
        this.error = "No saved data yet. Connect once to load your teams.";
      } finally {
        this.loading = false;
      }
    },
    canManage(team) {
      return this.isAdmin || team.manager_id === auth.state.userId;
    },
    notMembers(team) {
      const ids = team.members.map((m) => m.id);
      return this.users.filter((u) => !ids.includes(u.id));
    },
    // Runs an API change, shows any error, then reloads the teams
    async run(request, successMessage) {
      this.error = "";
      try {
        await request();
        vibrate();
        if (successMessage) toast(successMessage);
      } catch (err) {
        const data = err.response && err.response.data;
        this.error = (data && (data.error || JSON.stringify(data.errors))) || "Something went wrong.";
      }
      this.load();
    },
    addMember(team) {
      const userId = this.toAdd[team.id];
      this.$set(this.toAdd, team.id, "");
      return this.run(() => api.post(`/teams/${team.id}/users/${userId}`), "Member added");
    },
    removeMember(team, member) {
      return this.run(
        () => api.delete(`/teams/${team.id}/users/${member.id}`),
        `${member.username} removed`
      );
    },
    setManager(team, managerId) {
      const id = managerId && managerId !== "null" ? Number(managerId) : null;
      return this.run(() => api.put(`/teams/${team.id}`, { manager_id: id }), "Manager updated");
    },
    async deleteTeam(team) {
      const ok = await confirmDialog("Delete team", `Delete the team ${team.name}?`, "Delete");
      if (!ok) return;
      return this.run(() => api.delete(`/teams/${team.id}`), "Team deleted");
    },
    // Only one field is needed (the name) -> perfect for a native prompt dialog
    async createTeam() {
      const name = await promptDialog("New team", "Name of the team", "e.g. Police department", "Create");
      if (!name) return;
      return this.run(() => api.post("/teams", { name }), `Team "${name}" created`);
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
.team {
  margin-bottom: 14px;
}
.team-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.team-head h3 {
  margin: 0;
}
.label {
  display: block;
  margin: 14px 0 6px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--muted);
}
.manager select {
  font-size: 15px;
}
.member {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f1f5f9;
}
.avatar-sm {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: #e0e7ff;
  color: var(--primary);
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
  font-size: 13px;
}
.remove {
  min-height: 36px;
  width: 36px;
  padding: 0;
  border-radius: 50%;
  background: #fee2e2;
  color: var(--red);
}
.muted {
  color: var(--muted);
  font-size: 14px;
}
.add-row {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}
.add-row select {
  flex: 1;
}
.small {
  min-height: 36px;
  font-size: 14px;
}
.new-team {
  width: 100%;
  margin-top: 8px;
}
</style>