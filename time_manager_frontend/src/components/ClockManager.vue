<template>
  <div class="clock-manager">
    <h2>Clock for user {{ userId }}</h2>

    <p v-if="error" class="error">{{ error }}</p>

    <div v-else>
      <p v-if="clockIn">
        Currently <strong>clocked in</strong> since {{ startDateTime }}
      </p>
      <p v-else>Currently <strong>clocked out</strong></p>

      <button @click="clock">
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

<style>
.clock-manager {
  padding: 10px 20px;
}
.error {
  color: red;
}
button {
  font-size: 1.1em;
  padding: 10px 20px;
}
</style>