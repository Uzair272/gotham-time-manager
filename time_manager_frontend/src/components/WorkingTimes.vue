<template>
  <div class="working-times">
    <h2>Working times for user {{ userId }}</h2>

    <router-link :to="'/workingTime/' + userId">+ Add a working time</router-link>

    <p v-if="error" class="error">{{ error }}</p>

    <table v-if="workingTimes.length">
      <thead>
        <tr>
          <th>Start</th>
          <th>End</th>
          <th>Duration</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="wt in workingTimes" :key="wt.id">
          <td>{{ wt.start }}</td>
          <td>{{ wt.end }}</td>
          <td>{{ duration(wt) }}</td>
          <td>
            <router-link :to="'/workingTime/' + userId + '/' + wt.id"
              >Edit</router-link
            >
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else-if="!error">No working times recorded yet.</p>
  </div>
</template>

<script>
import api from "../api";

export default {
  name: "WorkingTimes",
  props: ["userid"],
  data() {
    return {
      userId: this.userid || this.$route.params.userID,
      workingTimes: [],
      error: "",
    };
  },
  created() {
    this.getWorkingTimes();
  },
  watch: {
    "$route.params.userID"() {
      this.userId = this.$route.params.userID;
      this.getWorkingTimes();
    },
  },
  methods: {
    getWorkingTimes() {
      api.get(`/workingtime/${this.userId}`).then(
        (response) => {
          this.workingTimes = response.data.data;
          this.error = "";
        },
        () => {
          this.error = "Unable to retrieve working times for this user.";
        }
      );
    },
    duration(wt) {
      const start = new Date(wt.start.replace(" ", "T"));
      const end = new Date(wt.end.replace(" ", "T"));
      const hours = (end - start) / 1000 / 60 / 60;
      return hours.toFixed(2) + " h";
    },
  },
};
</script>

<style>
.working-times {
  padding: 10px 20px;
}
table {
  border-collapse: collapse;
  margin-top: 10px;
  width: 100%;
  max-width: 700px;
}
th,
td {
  border: 1px solid #ccc;
  padding: 6px 12px;
  text-align: left;
}
.error {
  color: red;
}
</style>