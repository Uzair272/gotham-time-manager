<template>
  <div class="working-times">
    <div class="page-head">
      <h2>Working times</h2>
      <router-link :to="'/workingTime/' + userId" class="add-btn">+ Add a working time</router-link>
    </div>

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
          <td><span class="dur">{{ duration(wt) }}</span></td>
          <td>
            <router-link :to="'/workingTime/' + userId + '/' + wt.id" class="link-edit">Edit</router-link>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-else-if="!error" class="card empty">No working times recorded yet.</div>
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

<style scoped>
.page-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  flex-wrap: wrap;
  gap: 10px;
}
.page-head h2 {
  margin: 0;
}
.add-btn {
  text-decoration: none;
  background: linear-gradient(90deg, var(--primary), var(--primary-2));
  color: #fff;
  padding: 10px 18px;
  border-radius: 999px;
  font-weight: 700;
  font-size: 14px;
}
.dur {
  background: rgba(59, 130, 246, 0.12);
  color: var(--primary-2);
  border-radius: 8px;
  padding: 3px 10px;
  font-weight: 700;
  font-size: 13px;
}
.link-edit {
  font-weight: 600;
  text-decoration: none;
}
.empty {
  color: var(--muted);
  text-align: center;
}
</style>
