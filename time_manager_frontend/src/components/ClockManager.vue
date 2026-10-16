<template>
  <div class="clock-manager">
    <h2>My clock</h2>

    <p v-if="error" class="error">{{ error }}</p>

    <div v-else class="card clock-card">
      <span class="chip" :class="clockIn ? 'on' : 'off'">
        <span class="dot"></span>{{ clockIn ? "On duty" : "Off duty" }}
      </span>

      <p class="since" v-if="clockIn">Clocked in since {{ startDateTime }}</p>
      <p class="since" v-else>Tap the button to start your shift</p>

      <button class="clock-btn" :class="{ 'is-in': clockIn }" @click="clock">
        <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
        {{ clockIn ? "Clock out" : "Clock in" }}
      </button>
    </div>
  </div>
</template>

<script>
import api from "../api";

function formatDate(isoString) {
  if (!isoString) return null;
  const d = new Date(isoString);
  const pad = (n) => String(n).padStart(2, "0");
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  );
}

export default {
  name: "ClockManager",
  props: ["userid"],
  data() {
    return {
      userId: this.userid || this.$route.params.userid,
      startDateTime: null,
      clockIn: false,
      error: "",
    };
  },
  created() {
    this.refresh();
  },
  methods: {
    refresh() {
      api.get(`/clocks/${this.userId}`).then(
        (response) => {
          const clocks = response.data.data;
          if (clocks.length === 0) {
            this.clockIn = false;
            this.startDateTime = null;
          } else {
            const last = clocks[0];
            this.clockIn = last.status === true;
            this.startDateTime = this.clockIn ? formatDate(last.time) : null;
          }
          this.error = "";
        },
        () => {
          this.error = "Unable to retrieve clock status for this user.";
        }
      );
    },
    clock() {
      api.post(`/clocks/${this.userId}`).then(
        () => {
          this.refresh();
        },
        (err) => {
          this.error = "Could not clock: " + JSON.stringify(err.response.data);
        }
      );
    },
  },
};
</script>

<style scoped>
.clock-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  text-align: center;
  padding: 36px 20px;
}
.chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 16px;
  border-radius: 999px;
  font-weight: 700;
  font-size: 14px;
}
.chip .dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
}
.chip.on {
  background: rgba(16, 185, 129, 0.12);
  color: #059669;
}
.chip.on .dot {
  background: #059669;
}
.chip.off {
  background: rgba(100, 116, 139, 0.14);
  color: var(--muted);
}
.chip.off .dot {
  background: var(--muted);
}
.since {
  color: var(--muted);
  margin: 0;
}
.clock-btn {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 18px 40px;
  border-radius: 999px;
  font-size: 18px;
  font-weight: 800;
  background: linear-gradient(135deg, #10b981, #059669);
  box-shadow: 0 8px 22px rgba(16, 185, 129, 0.35);
}
.clock-btn svg {
  color: #fff;
  width: 22px;
  height: 22px;
}
.clock-btn.is-in {
  background: linear-gradient(135deg, #ef4444, #b91c1c);
  box-shadow: 0 8px 22px rgba(239, 68, 68, 0.35);
}
</style>
