<template>
  <div class="chart-manager">
    <h2>Charts for user {{ userId }}</h2>

    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="!hasData">No working times yet, nothing to chart.</p>

    <div v-else>
      <div class="chart-box">
        <h3>Hours worked per day (bar)</h3>
        <bar-chart
          :chart-data="hoursPerDayData"
          :options="chartOptions"
          :height="250"
        />
      </div>

      <div class="chart-box">
        <h3>Hours worked over time (line)</h3>
        <line-chart
          :chart-data="hoursPerDayData"
          :options="chartOptions"
          :height="250"
        />
      </div>

      <div class="chart-box">
        <h3>Share of total hours per day (pie)</h3>
        <pie-chart
          :chart-data="pieData"
          :options="chartOptions"
          :height="250"
        />
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
            backgroundColor: "#3b8dd4",
            borderColor: "#3b8dd4",
            fill: false,
            data: hours,
          },
        ],
      };

      const colors = [
        "#3b8dd4",
        "#e07b39",
        "#4caf50",
        "#9c27b0",
        "#f44336",
        "#ffc107",
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

<style>
.chart-manager {
  padding: 10px 20px;
}
.chart-box {
  position: relative;
  height: 300px;
  max-width: 600px;
  margin-bottom: 60px;
  overflow: hidden;
}
.error {
  color: red;
}
</style>