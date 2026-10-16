<template>
  <div class="working-time-form">
    <h2>{{ isEditing ? "Edit" : "New" }} working time</h2>

    <div class="card">
      <form class="form" @submit.prevent="save">
        <label>Start (YYYY-MM-DD hh:mm:ss)</label>
        <input v-model="start" placeholder="2026-09-27 09:00:00" />

        <label>End (YYYY-MM-DD hh:mm:ss)</label>
        <input v-model="end" placeholder="2026-09-27 17:00:00" />

        <p v-if="error" class="error">{{ error }}</p>

        <div class="actions">
          <button type="submit">{{ isEditing ? "Save" : "Create" }}</button>
          <button v-if="isEditing" type="button" @click="deleteWorkingTime" class="danger">
            Delete
          </button>
          <router-link :to="'/workingTimes/' + userId" class="cancel">Cancel</router-link>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import api from "../api";

export default {
  name: "WorkingTime",
  data() {
    return {
      userId: this.$route.params.userid,
      workingTimeId: this.$route.params.workingtimeid || null,
      start: "",
      end: "",
      error: "",
    };
  },
  computed: {
    isEditing() {
      return !!this.workingTimeId;
    },
  },
  created() {
    if (this.isEditing) {
      this.loadExisting();
    }
  },
  methods: {
    loadExisting() {
      api.get(`/workingtime/${this.userId}/${this.workingTimeId}`).then(
        (response) => {
          this.start = response.data.data.start;
          this.end = response.data.data.end;
        },
        () => {
          this.error = "Could not load this working time.";
        }
      );
    },
    save() {
      if (this.isEditing) {
        this.updateWorkingTime();
      } else {
        this.createWorkingTime();
      }
    },
    createWorkingTime() {
      api
        .post(`/workingtime/${this.userId}`, {
          start: this.start,
          end: this.end,
        })
        .then(
          () => {
            this.$router.push(`/workingTimes/${this.userId}`);
          },
          (err) => {
            this.error = "Could not create: " + JSON.stringify(err.response.data);
          }
        );
    },
    updateWorkingTime() {
      api
        .put(`/workingtime/${this.workingTimeId}`, {
          start: this.start,
          end: this.end,
        })
        .then(
          () => {
            this.$router.push(`/workingTimes/${this.userId}`);
          },
          (err) => {
            this.error = "Could not update: " + JSON.stringify(err.response.data);
          }
        );
    },
    deleteWorkingTime() {
      api.delete(`/workingtime/${this.workingTimeId}`).then(
        () => {
          this.$router.push(`/workingTimes/${this.userId}`);
        },
        () => {
          this.error = "Could not delete this working time.";
        }
      );
    },
  },
};
</script>

<style scoped>
.working-time-form {
  max-width: 460px;
}
.working-time-form label {
  font-weight: 600;
  font-size: 14px;
}
.actions {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 6px;
}
.cancel {
  text-decoration: none;
  color: var(--muted);
  font-weight: 600;
}
</style>
