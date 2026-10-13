<template>
  <div>
    <!-- Summary -->
    <div class="summary card">
      <div>
        <span class="big">{{ totalHours }}</span><span class="unit">h</span>
        <p>Total recorded</p>
      </div>
      <div>
        <span class="big">{{ workingTimes.length }}</span>
        <p>Entries</p>
      </div>
    </div>

    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="loaded && !workingTimes.length" class="empty">
      No working times yet.<br />Tap + to add one.
    </p>

    <h3 v-if="workingTimes.length" class="section-title">History</h3>

    <!-- One card per working time, tap to edit -->
    <router-link
      v-for="wt in sorted"
      :key="wt.id"
      :to="'/workingTime/' + userId + '/' + wt.id"
      class="wt-card card"
    >
      <div class="date-badge">
        <span class="day">{{ toDate(wt.start).getDate() }}</span>
        <span class="month">{{ month(wt.start) }}</span>
      </div>
      <div class="info">
        <strong>{{ time(wt.start) }} – {{ time(wt.end) }}</strong>
        <span>{{ weekday(wt.start) }}</span>
      </div>
      <span class="pill">{{ duration(wt) }}</span>
    </router-link>

    <!-- Floating action button -->
    <router-link :to="'/workingTime/' + userId" class="fab" aria-label="Add a working time">+</router-link>
  </div>
</template>

<script>
import { cachedGet } from "../offline";

const pad = (n) => String(n).padStart(2, "0");

export default {
  name: "WorkingTimes",
  data() {
    return {
      userId: this.$route.params.userID,
      workingTimes: [],
      loaded: false,
      error: "",
    };
  },
  computed: {
    // Newest first
    sorted() {
      return [...this.workingTimes].sort((a, b) => this.toDate(b.start) - this.toDate(a.start));
    },
    totalHours() {
      const total = this.workingTimes.reduce((sum, wt) => sum + this.hours(wt), 0);
      return total.toFixed(1);
    },
  },
  created() {
    this.load();
  },
  methods: {
    // Online: from the API (and saved in the cache). Offline: from the cache.
    async load() {
      try {
        const { data } = await cachedGet(`/workingtime/${this.userId}`);
        this.workingTimes = data.data;
        this.error = "";
      } catch (err) {
        this.error = "No saved data yet. Connect once to load your working times.";
      } finally {
        this.loaded = true;
      }
    },
    // Accepts "2026-10-13 09:00:00" and "2026-10-13T09:00:00Z"
    toDate(value) {
      return new Date(String(value).replace(" ", "T"));
    },
    hours(wt) {
      return (this.toDate(wt.end) - this.toDate(wt.start)) / 3600000;
    },
    duration(wt) {
      const minutes = Math.round(this.hours(wt) * 60);
      return `${Math.floor(minutes / 60)}h${pad(minutes % 60)}`;
    },
    time(value) {
      const d = this.toDate(value);
      return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
    },
    month(value) {
      return this.toDate(value).toLocaleDateString("en-GB", { month: "short" });
    },
    weekday(value) {
      return this.toDate(value).toLocaleDateString("en-GB", { weekday: "long" });
    },
  },
};
</script>

<style scoped>
.summary {
  display: flex;
  justify-content: space-around;
  text-align: center;
  background: linear-gradient(135deg, var(--primary), var(--primary-2));
  color: #fff;
}
.summary p {
  margin: 4px 0 0;
  opacity: 0.8;
  font-size: 13px;
}
.big {
  font-size: 32px;
  font-weight: 800;
}
.unit {
  margin-left: 2px;
  opacity: 0.8;
}
.wt-card {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 10px;
  text-decoration: none;
  color: var(--text);
}
.date-badge {
  width: 50px;
  height: 54px;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #e0e7ff;
  color: var(--primary);
}
.date-badge .day {
  font-size: 20px;
  font-weight: 800;
  line-height: 1;
}
.date-badge .month {
  font-size: 12px;
  text-transform: uppercase;
}
.info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.info span {
  color: var(--muted);
  font-size: 14px;
}
</style>