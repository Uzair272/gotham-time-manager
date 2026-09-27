<template>
  <div id="app">
    <User @user-loaded="onUserLoaded" />

    <nav v-if="currentUser" class="main-nav">
      <router-link :to="'/workingTimes/' + currentUser.id">Working times</router-link>
      <router-link :to="'/clock/' + currentUser.id">Clock</router-link>
      <router-link :to="'/chartManager/' + currentUser.id">Charts</router-link>
    </nav>

    <router-view />
  </div>
</template>

<script>
import User from "./components/User.vue";

export default {
  name: "App",
  components: {
    User,
  },
  data() {
    return {
      currentUser: null,
    };
  },
  methods: {
    onUserLoaded(user) {
      this.currentUser = user;
    },
  },
};
</script>

<style>
.main-nav {
  background-color: #eee;
  padding: 10px 20px;
  margin-bottom: 15px;
}
.main-nav a {
  margin-right: 15px;
}
</style>