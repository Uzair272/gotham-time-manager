<template>
  <div>
    <h2>Create an account</h2>
    <form class="form" @submit.prevent="signUp">
      <input v-model="username" placeholder="Username" required />
      <input v-model="email" type="email" placeholder="Email" required />
      <input v-model="password" type="password" placeholder="Password (8 characters min.)" required />
      <input v-model="confirm" type="password" placeholder="Confirm password" required />
      <button type="submit" :disabled="loading">Sign up</button>
      <p v-if="error" class="error">{{ error }}</p>
    </form>
    <p>Already have an account? <router-link to="/sign_in">Sign in</router-link></p>
  </div>
</template>

<script>
import auth from "../auth";

export default {
  name: "SignUp",
  data() {
    return { username: "", email: "", password: "", confirm: "", error: "", loading: false };
  },
  methods: {
    async signUp() {
      this.error = "";
      if (this.password.length < 8) {
        this.error = "The password must be at least 8 characters.";
        return;
      }
      if (this.password !== this.confirm) {
        this.error = "The two passwords are different.";
        return;
      }
      this.loading = true;
      try {
        await auth.signUp(this.username, this.email, this.password);
        this.$router.push("/");
      } catch (err) {
        const errors = err.response && err.response.data && err.response.data.errors;
        this.error = errors
          ? Object.entries(errors)
              .map(([field, messages]) => `${field} ${messages.join(", ")}`)
              .join(" / ")
          : "Could not create the account.";
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
