<template>
  <div id="app">
    <nav class="main-nav">
      <router-link to="/" exact>Home</router-link>

      <!-- v-if (not v-show): hidden links are not even in the page -->
      <template v-if="isLoggedIn">
        <router-link :to="'/clock/' + userId">Clock</router-link>
        <router-link :to="'/workingTimes/' + userId">Working times</router-link>
        <router-link :to="'/chartManager/' + userId">Charts</router-link>
        <router-link to="/teams">Teams</router-link>
        <router-link v-if="isManagerOrAdmin" to="/users">Users</router-link>
        <router-link to="/profile">Profile</router-link>

        <span class="who">
          {{ username }} <span class="role-badge">{{ role }}</span>
        </span>
        <button @click="logout">Log out</button>
      </template>

      <template v-else>
        <router-link to="/sign_in">Sign in</router-link>
        <router-link to="/sign_up">Sign up</router-link>
      </template>
    </nav>

    <router-view :key="$route.fullPath" />
  </div>
</template>

<script>
import auth from "./auth";

export default {
  name: "App",
  computed: {
    isLoggedIn() {
      return auth.isLoggedIn();
    },
    userId() {
      return auth.state.userId;
    },
    role() {
      return auth.state.role;
    },
    username() {
      return auth.state.user ? auth.state.user.username : "";
    },
    isManagerOrAdmin() {
      return auth.hasRole("manager", "admin");
    },
  },
  methods: {
    async logout() {
      await auth.signOut();
      this.$router.push("/sign_in");
    },
  },
};
</script>

<style>
body {
  font-family: Arial, sans-serif;
  margin: 0;
}
#app {
  padding: 0 20px 20px;
}
.main-nav {
  background-color: #eee;
  padding: 10px 20px;
  margin: 0 -20px 15px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 15px;
}
.main-nav a.router-link-active {
  font-weight: bold;
}
.who {
  margin-left: auto;
}
.role-badge {
  background: #333;
  color: #fff;
  border-radius: 4px;
  padding: 2px 6px;
  font-size: 12px;
}
.error {
  color: red;
}
.success {
  color: green;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-width: 320px;
}
table {
  border-collapse: collapse;
}
th,
td {
  border: 1px solid #ccc;
  padding: 6px 10px;
  text-align: left;
}
</style>
