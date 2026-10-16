<template>
  <div class="chart-manager">
    <h2>My charts</h2>

    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="!hasData" class="card empty">No working times yet, nothing to chart.</p>

    <div v-else class="chart-grid">
      <div class="card chart-box">
        <h3>Hours worked per day</h3>
        <div class="canvas-wrap">
          <bar-chart :chart-data="hoursPerDayData" :options="chartOptions" :height="250" />
        </div>
      </div>

      <div class="card chart-box">
        <h3>Hours worked over time</h3>
        <div class="canvas-wrap">
          <line-chart :chart-data="hoursPerDayData" :options="chartOptions" :height="250" />
        </div>
      </div>

      <div class="card chart-box">
        <h3>Share of total hours per day</h3>
        <div class="canvas-wrap">
          <pie-chart :chart-data="pieData" :options="chartOptions" :height="250" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from "../api";
import BarChart from "./BarChart.js";
import LineChart from "./LineChart.js";
import PieChart from "./PieChart.js";

export default {
  name: "ChartManager",
  props: ["userid"],
  components: {
    "bar-chart": BarChart,
    "line-chart": LineChart,
    "pie-chart": PieChart,
  },
  data() {
    return {
      userId: this.userid || this.$route.params.userid,
      workingTimes: [],
      hoursPerDayData: null,
      pieData: null,
      chartOptions: {
        responsive: true,
        maintainAspectRatio: false,
      },
      error: "",
    };
  },
  computed: {
    hasData() {
      return this.workingTimes.length > 0;
    },
  },
  created() {
    this.getWorkingTimes();
  },
  methods: {
    getWorkingTimes() {
      api.get(`/workingtime/${this.userId}`).then(
        (response) => {
          this.workingTimes = response.data.data;
          this.buildCharts();
          this.error = "";
        },
        () => {
          this.error = "Unable to retrieve working times for this user.";
        }
      );
    },
    hoursFor(wt) {
      const start = new Date(wt.start.replace(" ", "T"));
      const end = new Date(wt.end.replace(" ", "T"));
      return (end - start) / 1000 / 60 / 60;
    },
    buildCharts() {
      const labels = this.workingTimes.map((wt) => wt.start.split(" ")[0]);
      const hours = this.workingTimes.map((wt) => this.hoursFor(wt));

      this.hoursPerDayData = {
        labels,
        datasets: [
          {
            label: "Hours worked",
            backgroundColor: "#3b82f6",
            borderColor: "#1e3a8a",
            fill: false,
            data: hours,
          },
        ],
      };

      const colors = [
        "#3b82f6",
        "#f5b301",
        "#10b981",
        "#8b5cf6",
        "#ef4444",
        "#06b6d4",
      ];
      this.pieData = {
        labels,
        datasets: [
          {
            backgroundColor: labels.map((_, i) => colors[i % colors.length]),
            data: hours,
          },
        ],
      };
    },
  },
};
</script>

<style scoped>
.chart-grid {
  display: grid;
  gap: 18px;
}
.chart-box h3 {
  margin-top: 0;
}
.canvas-wrap {
  position: relative;
  height: 280px;
}
.empty {
  text-align: center;
  color: var(--muted);
}
</style>
