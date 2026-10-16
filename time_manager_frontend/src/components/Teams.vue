<template>
  <div>
    <h2>Teams</h2>
    <p v-if="error" class="error">{{ error }}</p>
    <p v-if="!loading && teams.length === 0" class="card empty">No team to show.</p>

    <div v-for="team in teams" :key="team.id" class="card team">
      <div class="team-head">
        <h3>{{ team.name }}</h3>
        <button v-if="isAdmin" class="small danger" @click="deleteTeam(team)">Delete team</button>
      </div>

      <p class="mgr">
        Manager:
        <select
          v-if="isAdmin"
          :value="team.manager_id"
          @change="setManager(team, $event.target.value)"
        >
          <option :value="null">(none)</option>
          <option v-for="m in managers" :key="m.id" :value="m.id">{{ m.username }}</option>
        </select>
        <span v-else class="pill">{{ team.manager ? team.manager.username : "none" }}</span>
      </p>

      <ul class="members">
        <li v-for="member in team.members" :key="member.id">
          <span><strong>{{ member.username }}</strong> <span class="muted">{{ member.email }}</span></span>
          <button v-if="canManage(team)" class="small" @click="removeMember(team, member)">
            Remove
          </button>
        </li>
        <li v-if="team.members.length === 0" class="muted">No members yet.</li>
      </ul>

      <div v-if="canManage(team)" class="add-row">
        <select v-model="toAdd[team.id]">
          <option disabled value="">Add someone...</option>
          <option v-for="u in notMembers(team)" :key="u.id" :value="u.id">
            {{ u.username }} ({{ u.role }})
          </option>
        </select>
        <button :disabled="!toAdd[team.id]" @click="addMember(team)">Add</button>
      </div>
    </div>

    <div v-if="isAdmin" class="card">
      <h3>New team</h3>
      <form class="form" @submit.prevent="createTeam">
        <input v-model="newTeam.name" placeholder="Team name" required />
        <select v-model="newTeam.manager_id">
          <option :value="null">No manager</option>
          <option v-for="m in managers" :key="m.id" :value="m.id">{{ m.username }}</option>
        </select>
        <button type="submit">Create team</button>
      </form>
    </div>
  </div>
</template>

<script>
import api from "../api";
import auth from "../auth";

export default {
  name: "TeamsPage",
  data() {
    return {
      teams: [],
      users: [],
      toAdd: {},
      newTeam: { name: "", manager_id: null },
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
    async load() {
      this.loading = true;
      try {
        const { data } = await api.get("/teams");
        this.teams = data.data;
        if (auth.hasRole("manager", "admin")) {
          const users = await api.get("/users");
          this.users = users.data.data;
        }
      } catch (err) {
        this.error = "Could not load teams.";
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
    async run(request) {
      this.error = "";
      try {
        await request();
      } catch (err) {
        const data = err.response && err.response.data;
        this.error = (data && (data.error || JSON.stringify(data.errors))) || "Something went wrong.";
      }
      this.load();
    },
    addMember(team) {
      const userId = this.toAdd[team.id];
      this.$set(this.toAdd, team.id, "");
      return this.run(() => api.post(`/teams/${team.id}/users/${userId}`));
    },
    removeMember(team, member) {
      return this.run(() => api.delete(`/teams/${team.id}/users/${member.id}`));
    },
    setManager(team, managerId) {
      const id = managerId && managerId !== "null" ? Number(managerId) : null;
      return this.run(() => api.put(`/teams/${team.id}`, { manager_id: id }));
    },
    deleteTeam(team) {
      if (!window.confirm(`Delete the team ${team.name}?`)) return;
      return this.run(() => api.delete(`/teams/${team.id}`));
    },
    createTeam() {
      const body = { ...this.newTeam };
      this.newTeam = { name: "", manager_id: null };
      return this.run(() => api.post("/teams", body));
    },
  },
};
</script>

<style scoped>
.team-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.team-head h3 {
  margin: 0;
}
.mgr {
  color: var(--muted);
}
.pill {
  background: #f1f5f9;
  border-radius: 999px;
  padding: 2px 10px;
  color: var(--text);
  font-weight: 600;
}
.members {
  list-style: none;
  padding: 0;
  margin: 10px 0;
}
.members li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f1f5f9;
}
.add-row {
  display: flex;
  gap: 10px;
  margin-top: 8px;
}
.small {
  font-size: 12px;
  padding: 6px 12px;
}
.muted {
  color: var(--muted);
}
.empty {
  text-align: center;
  color: var(--muted);
}
</style>
