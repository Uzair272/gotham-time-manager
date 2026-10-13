<template>
  <div>
    <h2>Sign in</h2>
    <form class="form" @submit.prevent="signIn">
      <input v-model="email" type="email" placeholder="Email" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <button type="submit" :disabled="loading">Sign in</button>
      <p v-if="error" class="error">{{ error }}</p>
    </form>
    <p>No account yet? <router-link to="/sign_up">Sign up</router-link></p>
  </div>
</template>

<script>
import auth from "../auth";

export default {
  name: "SignIn",
  data() {
    return { email: "", password: "", error: "", loading: false };
  },
  methods: {
    async signIn() {
      this.error = "";
      this.loading = true;
      try {
        await auth.signIn(this.email, this.password);
        // Go back to the page the user wanted, or home
        this.$router.push(this.$route.query.redirect || "/");
      } catch (err) {
        this.error =
          err.response && err.response.status === 401
            ? "Wrong email or password."
            : "Could not sign in. Is the API running?";
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
