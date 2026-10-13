<template>
  <div class="clock-page">
    <p class="greeting">
      {{ greeting }}<span v-if="name">, {{ name }}</span> 👋
    </p>
    <p class="date">{{ today }}</p>

    <!-- Status + live timer -->
    <div class="status card">
      <span class="chip" :class="clockIn ? 'on' : 'off'">
        <span class="dot"></span>{{ clockIn ? "On duty" : "Off duty" }}
      </span>
      <div class="timer">{{ clockIn ? elapsed : "--:--:--" }}</div>
      <p class="since">
        {{ clockIn ? "since " + formatTime(since) : "Tap the button to start your day" }}
      </p>
    </div>

    <!-- The big button -->
    <button
      class="clock-btn"
      :class="{ 'is-in': clockIn }"
      :disabled="loading"
      @click="clock"
    >
      <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>
      <span>{{ clockIn ? "Clock out" : "Clock in" }}</span>
    </button>

    <p v-if="error" class="error">{{ error }}</p>

    <!-- Recent activity -->
    <h3 v-if="history.length" class="section-title">Recent activity</h3>
    <ul class="timeline card" v-if="history.length">
      <li v-for="c in history" :key="c.id">
        <span class="tl-dot" :class="c.status ? 'in' : 'out'"></span>
        <span class="tl-label">
          {{ c.status ? "Clocked in" : "Clocked out" }}
          <em v-if="c.pending" class="not-synced">not synced</em>
        </span>
        <span class="tl-time">{{ formatDateTime(c.time) }}</span>
      </li>
    </ul>
  </div>
</template>

<script>
import auth from "../auth";
import { cachedGet, cacheSet, send } from "../offline";
import { vibrate, toast } from "../native";

const pad = (n) => String(n).padStart(2, "0");

export default {
  name: "ClockManager",
  data() {
    return {
      userId: this.$route.params.userid,
      clocks: [], // newest first
      now: new Date(), // updated every second -> live timer
      loading: false,
      error: "",
      ticker: null,
    };
  },
  computed: {
    url() {
      return `/clocks/${this.userId}`;
    },
    last() {
      return this.clocks[0] || null;
    },
    // Last clock = arrival (true) -> currently clocked in
    clockIn() {
      return Boolean(this.last && this.last.status);
    },
    since() {
      return this.clockIn ? new Date(this.last.time) : null;
    },
    elapsed() {
      const s = Math.max(0, Math.floor((this.now - this.since) / 1000));
      return `${pad(Math.floor(s / 3600))}:${pad(Math.floor((s % 3600) / 60))}:${pad(s % 60)}`;
    },
    history() {
      return this.clocks.slice(0, 6);
    },
    isMe() {
      return String(this.userId) === String(auth.state.userId);
    },
    name() {
      return this.isMe && auth.state.user ? auth.state.user.username : "";
    },
    greeting() {
      const h = this.now.getHours();
      if (h < 12) return "Good morning";
      if (h < 18) return "Good afternoon";
      return "Good evening";
    },
    today() {
      return this.now.toLocaleDateString("en-GB", {
        weekday: "long",
        day: "numeric",
        month: "long",
      });
    },
  },
  created() {
    this.refresh();
  },
  mounted() {
    this.ticker = setInterval(() => {
      this.now = new Date();
    }, 1000);
  },
  beforeDestroy() {
    clearInterval(this.ticker);
  },
  methods: {
    // Online: from the API (and saved in the cache). Offline: from the cache.
    async refresh() {
      try {
        const { data } = await cachedGet(this.url);
        this.clocks = data.data;
        this.error = "";
      } catch (err) {
        this.error = "No saved data yet. Connect once to load your clock.";
      }
    },
    async clock() {
      this.loading = true;
      this.error = "";

      // We send the REAL time of the tap and the expected status.
      // Offline, the request waits in the queue but keeps this time.
      // The status lets the API detect a conflict (e.g. already clocked in on the website).
      const body = { time: new Date().toISOString(), status: !this.clockIn };

      try {
        const result = await send("post", this.url, body, async () => {
          // Offline: show the change immediately, marked as "not synced"
          const local = { id: "local-" + Date.now(), ...body, pending: true };
          this.clocks = [local, ...this.clocks];
          await cacheSet(this.url, { data: this.clocks });
        });

        vibrate(); // native haptic feedback
        if (result.queued) {
          toast("Saved offline. It will sync when you're back online.");
        } else {
          await this.refresh();
        }
      } catch (err) {
        const data = err.response && err.response.data;
        this.error = (data && data.error) || "Could not clock.";
      } finally {
        this.loading = false;
      }
    },
    formatTime(date) {
      return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
    },
    formatDateTime(iso) {
      const d = new Date(iso);
      return (
        d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }) +
        " · " +
        this.formatTime(d)
      );
    },
  },
};
</script>

<style scoped>
.greeting {
  margin: 4px 0 0;
  font-size: 22px;
  font-weight: 700;
}
.date {
  margin: 2px 0 16px;
  color: var(--muted);
}
.status {
  text-align: center;
}
.chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 600;
}
.chip .dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}
.chip.on {
  background: #d1fae5;
  color: #047857;
}
.chip.off {
  background: #f1f5f9;
  color: var(--muted);
}
.timer {
  margin: 12px 0 4px;
  font-size: 44px;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  letter-spacing: 1px;
}
.since {
  margin: 0;
  color: var(--muted);
}
.clock-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 180px;
  height: 180px;
  margin: 28px auto 8px;
  border-radius: 50%;
  font-size: 20px;
  background: linear-gradient(135deg, #34d399, var(--green));
  box-shadow: 0 12px 30px rgba(16, 185, 129, 0.45);
}
.clock-btn svg {
  width: 44px;
  height: 44px;
}
.clock-btn.is-in {
  background: linear-gradient(135deg, #f87171, var(--red));
  box-shadow: 0 12px 30px rgba(239, 68, 68, 0.45);
  animation: pulse 2s infinite;
}
@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.5);
  }
  70% {
    box-shadow: 0 0 0 24px rgba(239, 68, 68, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0);
  }
}
.error {
  text-align: center;
}
.timeline {
  list-style: none;
  margin: 0;
  padding: 8px 16px;
}
.timeline li {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid #f1f5f9;
}
.timeline li:last-child {
  border-bottom: none;
}
.tl-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}
.tl-dot.in {
  background: var(--green);
}
.tl-dot.out {
  background: var(--red);
}
.tl-label {
  flex: 1;
  font-weight: 600;
}
.not-synced {
  margin-left: 6px;
  padding: 2px 6px;
  border-radius: 6px;
  background: #fef3c7;
  color: #92400e;
  font-size: 11px;
  font-style: normal;
}
.tl-time {
  color: var(--muted);
  font-size: 14px;
}
</style>