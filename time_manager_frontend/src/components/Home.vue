<template>
  <div>
    <h1>Gotham Time Manager</h1>

    <div v-if="isLoggedIn">
      <p>Welcome back, {{ username }}.</p>
      <ul>
        <li><router-link :to="'/clock/' + userId">Clock in / out</router-link></li>
        <li><router-link :to="'/workingTimes/' + userId">My working times</router-link></li>
        <li><router-link to="/teams">My teams</router-link></li>
        <li v-if="isManagerOrAdmin"><router-link to="/users">Users</router-link></li>
      </ul>
    </div>

    <div v-else>
      <p>Track your working hours at the Gotham town hall.</p>
      <router-link to="/sign_in">Sign in</router-link> or
      <router-link to="/sign_up">create an account</router-link>.
    </div>
  </div>
</template>

<script>
import auth from "../auth";

export default {
  name: "HomePage",
  computed: {
    isLoggedIn() {
      return auth.isLoggedIn();
    },
    userId() {
      return auth.state.userId;
    },
    username() {
      return auth.state.user ? auth.state.user.username : "";
    },
    isManagerOrAdmin() {
      return auth.hasRole("manager", "admin");
    },
  },
};
</script>
