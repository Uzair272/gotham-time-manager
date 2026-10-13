<template>
  <!-- Bottom navigation: always visible, reachable with the thumb -->
  <nav class="tab-bar">
    <router-link v-for="tab in tabs" :key="tab.label" :to="tab.to" class="tab">
      <span class="icon-wrap">
        <svg viewBox="0 0 24 24" v-html="tab.icon"></svg>
      </span>
      <span class="label">{{ tab.label }}</span>
    </router-link>
  </nav>
</template>

<script>
import auth from "../auth";

// Line icons (SVG paths)
const ICONS = {
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
  list: '<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>',
  team: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
  user: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
};

export default {
  name: "TabBar",
  computed: {
    // Tabs depend on the role: max 5, so the bar never gets crowded
    tabs() {
      const id = auth.state.userId;
      const tabs = [
        { to: "/clock/" + id, icon: ICONS.clock, label: "Clock" },
        { to: "/workingTimes/" + id, icon: ICONS.list, label: "Times" },
        { to: "/teams", icon: ICONS.team, label: "Teams" },
      ];
      if (auth.hasRole("manager", "admin")) {
        tabs.push({ to: "/users", icon: ICONS.grid, label: "Users" });
      }
      tabs.push({ to: "/profile", icon: ICONS.user, label: "Profile" });
      return tabs;
    },
  },
};
</script>

<style scoped>
.tab-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  height: var(--tab-height);
  display: flex;
  background: rgba(255, 255, 255, 0.96);
  border-top: 1px solid #e2e8f0;
  box-shadow: 0 -4px 20px rgba(15, 23, 42, 0.06);
  z-index: 10;
}
.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  text-decoration: none;
  color: var(--muted);
  font-size: 11px;
  font-weight: 600;
}
.icon-wrap {
  display: grid;
  place-items: center;
  width: 52px;
  height: 30px;
  border-radius: 999px;
  transition: background 0.2s;
}
.tab.router-link-active {
  color: var(--primary);
}
.tab.router-link-active .icon-wrap {
  background: #e0e7ff;
}
</style>