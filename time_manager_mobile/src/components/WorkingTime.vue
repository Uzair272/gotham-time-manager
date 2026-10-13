<template>
  <div>
    <form class="form card" @submit.prevent="save">
      <!-- type="datetime-local" opens Android's native date and time picker -->
      <label>
        Start
        <input v-model="start" type="datetime-local" required :disabled="isLocal" />
      </label>
      <label>
        End
        <input v-model="end" type="datetime-local" required :disabled="isLocal" />
      </label>

      <div v-if="durationText" class="duration">
        Duration <strong>{{ durationText }}</strong>
      </div>

      <p v-if="error" class="error">{{ error }}</p>

      <button type="submit" :disabled="saving || isLocal">
        {{ isEditing ? "Save changes" : "Add working time" }}
      </button>
      <button
        v-if="isEditing"
        type="button"
        class="danger"
        :disabled="saving || isLocal"
        @click="remove"
      >
        Delete
      </button>
    </form>
  </div>
</template>

<script>
import { cachedGet, cacheSet, send } from "../offline";
import { confirmDialog, toast, vibrate } from "../native";

const pad = (n) => String(n).padStart(2, "0");

// Date -> "YYYY-MM-DDTHH:mm": the format of <input type="datetime-local"> (local time)
function toInput(date) {
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}`
  );
}

// API value -> Date (accepts "2026-10-13 09:00:00" and "2026-10-13T09:00:00Z")
function fromApi(value) {
  return new Date(String(value).replace(" ", "T"));
}

// Date -> UTC ISO string without milliseconds, e.g. "2026-10-13T07:00:00Z"
function toApi(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

export default {
  name: "WorkingTime",
  data() {
    // New entry: default to today 09:00 -> 17:00
    const start = new Date();
    start.setHours(9, 0, 0, 0);
    const end = new Date();
    end.setHours(17, 0, 0, 0);

    return {
      userId: this.$route.params.userid,
      workingTimeId: this.$route.params.workingtimeid || null,
      start: toInput(start),
      end: toInput(end),
      error: "",
      saving: false,
    };
  },
  computed: {
    isEditing() {
      return Boolean(this.workingTimeId);
    },
    // Created offline and not synced yet: it has no real id on the server
    isLocal() {
      return String(this.workingTimeId).startsWith("local-");
    },
    listUrl() {
      return `/workingtime/${this.userId}`;
    },
    durationText() {
      const ms = new Date(this.end) - new Date(this.start);
      if (!(ms > 0)) return "";
      const minutes = Math.round(ms / 60000);
      return `${Math.floor(minutes / 60)}h${pad(minutes % 60)}`;
    },
  },
  async created() {
    if (!this.isEditing) return;
    // Load the entry from the list (works offline from the cache)
    try {
      const { data } = await cachedGet(this.listUrl);
      const wt = data.data.find((w) => String(w.id) === String(this.workingTimeId));
      if (!wt) {
        this.error = "Working time not found.";
        return;
      }
      this.start = toInput(fromApi(wt.start));
      this.end = toInput(fromApi(wt.end));
      if (this.isLocal) {
        this.error = "This entry isn't synced yet. You can edit it once it's synced.";
      }
    } catch (err) {
      this.error = "Could not load this working time.";
    }
  },
  methods: {
    // Update the saved list so offline changes show immediately
    async updateCachedList(change) {
      let list = [];
      try {
        list = (await cachedGet(this.listUrl)).data.data;
      } catch (e) {
        list = [];
      }
      await cacheSet(this.listUrl, { data: change(list) });
    },

    async save() {
      this.error = "";
      const startDate = new Date(this.start);
      const endDate = new Date(this.end);
      if (!(endDate > startDate)) {
        this.error = "The end must be after the start.";
        return;
      }

      // The input is in local time; the API stores UTC
      const body = { start: toApi(startDate), end: toApi(endDate) };
      const id = this.workingTimeId;

      this.saving = true;
      try {
        let result;
        if (this.isEditing) {
          result = await send("put", `/workingtime/${id}`, body, () =>
            this.updateCachedList((list) =>
              list.map((w) => (String(w.id) === String(id) ? { ...w, ...body, pending: true } : w))
            )
          );
        } else {
          result = await send("post", this.listUrl, body, () =>
            this.updateCachedList((list) => [
              ...list,
              { id: "local-" + Date.now(), user_id: Number(this.userId), ...body, pending: true },
            ])
          );
        }
        vibrate();
        toast(result.queued ? "Saved offline. It will sync later." : "Working time saved.");
        this.$router.push(`/workingTimes/${this.userId}`);
      } catch (err) {
        const data = err.response && err.response.data;
        this.error =
          data && data.errors
            ? Object.entries(data.errors)
                .map(([field, messages]) => `${field} ${messages.join(", ")}`)
                .join(" / ")
            : (data && data.error) || "Could not save.";
      } finally {
        this.saving = false;
      }
    },

    async remove() {
      const ok = await confirmDialog(
        "Delete working time",
        "Delete this working time? This cannot be undone.",
        "Delete"
      );
      if (!ok) return;

      const id = this.workingTimeId;
      this.saving = true;
      try {
        const result = await send("delete", `/workingtime/${id}`, null, () =>
          this.updateCachedList((list) => list.filter((w) => String(w.id) !== String(id)))
        );
        vibrate();
        toast(result.queued ? "Deleted offline. It will sync later." : "Working time deleted.");
        this.$router.push(`/workingTimes/${this.userId}`);
      } catch (err) {
        this.error = "Could not delete this working time.";
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>

<style scoped>
label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
  color: var(--muted);
}
.duration {
  display: flex;
  justify-content: space-between;
  padding: 12px 14px;
  border-radius: 12px;
  background: #e0e7ff;
  color: var(--primary);
}
</style>