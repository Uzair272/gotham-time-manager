<template>
  <div class="user-box">
    <div v-if="!currentUser">
      <h3>Who are you?</h3>
      <input v-model="idInput" placeholder="Enter your user ID" />
      <button @click="getUser">Load user</button>
      <p v-if="error" class="error">{{ error }}</p>

      <details>
        <summary>Or create a new user</summary>
        <input v-model="newUsername" placeholder="Username" />
        <input v-model="newEmail" placeholder="Email" />
        <button @click="createUser">Create</button>
      </details>
    </div>

    <div v-else class="current-user">
      <span>
        Logged in as <strong>{{ currentUser.username }}</strong>
        (id: {{ currentUser.id }}, {{ currentUser.email }})
      </span>

      <button @click="startEdit" v-if="!editing">Edit</button>
      <button @click="deleteUser">Delete</button>
      <button @click="logout">Switch user</button>

      <div v-if="editing" class="edit-box">
        <input v-model="editUsername" placeholder="Username" />
        <input v-model="editEmail" placeholder="Email" />
        <button @click="updateUser">Save</button>
        <button @click="editing = false">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script>
/* eslint-disable vue/multi-word-component-names */
import api from "../api";

export default {
  name: "User",
  data() {
    return {
      idInput: "",
      newUsername: "",
      newEmail: "",
      editUsername: "",
      editEmail: "",
      editing: false,
      currentUser: null,
      error: "",
    };
  },
  created() {
    const savedId = localStorage.getItem("currentUserId");
    if (savedId) {
      this.idInput = savedId;
      this.getUser();
    }
  },
  methods: {
    getUser() {
      if (!this.idInput) {
        this.error = "Please enter a user ID.";
        return;
      }
      api.get(`/users/${this.idInput}`).then(
        (response) => {
          this.currentUser = response.data.data;
          this.error = "";
          localStorage.setItem("currentUserId", this.currentUser.id);
          this.$emit("user-loaded", this.currentUser);
        },
        () => {
          this.error = "User not found.";
        }
      );
    },
    createUser() {
      api
        .post("/users", {
          username: this.newUsername,
          email: this.newEmail,
        })
        .then(
          (response) => {
            this.currentUser = response.data.data;
            this.error = "";
            localStorage.setItem("currentUserId", this.currentUser.id);
            this.$emit("user-loaded", this.currentUser);
          },
          (err) => {
            this.error = "Could not create user: " + JSON.stringify(err.response.data.errors);
          }
        );
    },
    startEdit() {
      this.editUsername = this.currentUser.username;
      this.editEmail = this.currentUser.email;
      this.editing = true;
    },
    updateUser() {
      api
        .put(`/users/${this.currentUser.id}`, {
          username: this.editUsername,
          email: this.editEmail,
        })
        .then(
          (response) => {
            this.currentUser = response.data.data;
            this.editing = false;
            this.$emit("user-loaded", this.currentUser);
          },
          (err) => {
            this.error = "Could not update user: " + JSON.stringify(err.response.data.errors);
          }
        );
    },
    deleteUser() {
      api.delete(`/users/${this.currentUser.id}`).then(() => {
        this.logout();
      });
    },
    logout() {
      this.currentUser = null;
      this.idInput = "";
      localStorage.removeItem("currentUserId");
      this.$emit("user-loaded", null);
    },
  },
};
</script>

<style>
.user-box {
  background-color: #ddd;
  padding: 10px 20px;
  margin-bottom: 15px;
}
.error {
  color: red;
}
.current-user button {
  margin-left: 5px;
}
</style>