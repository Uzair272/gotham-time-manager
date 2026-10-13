import Vue from "vue";
import api from "./api";

// Session of the signed-in user.
// - The JWT itself is in an HttpOnly cookie: JavaScript can't read it (that's the point).
// - What we keep in localStorage: xsrfToken, userId, role (returned by /users/sign_in).
const state = Vue.observable({
  xsrfToken: localStorage.getItem("xsrfToken"),
  userId: Number(localStorage.getItem("userId")) || null,
  role: localStorage.getItem("role"),
  user: null,
});

function save(xsrfToken, user) {
  localStorage.setItem("xsrfToken", xsrfToken);
  localStorage.setItem("userId", user.id);
  localStorage.setItem("role", user.role);
  localStorage.setItem("roleId", user.role_id);
  state.xsrfToken = xsrfToken;
  state.userId = user.id;
  state.role = user.role;
  state.user = user;
}

const auth = {
  state,

  isLoggedIn() {
    return Boolean(state.xsrfToken && state.userId);
  },

  hasRole(...roles) {
    return roles.includes(state.role);
  },

  async signIn(email, password) {
    const { data } = await api.post("/users/sign_in", { email, password });
    save(data.xsrf_token, data.user);
  },

  async signUp(username, email, password) {
    await api.post("/users/sign_up", { username, email, password });
    // Account created: sign in straight away
    await auth.signIn(email, password);
  },

  async signOut() {
    try {
      await api.post("/users/sign_out");
    } catch (e) {
      // Even if the API call fails, we forget the session locally
    }
    auth.clear();
  },

  // Re-reads the current user (and role) from the API, e.g. after a promotion
  async refresh() {
    const { data } = await api.get("/users/me");
    save(state.xsrfToken, data.data);
    return data.data;
  },

  clear() {
    ["xsrfToken", "userId", "role", "roleId"].forEach((key) => localStorage.removeItem(key));
    state.xsrfToken = null;
    state.userId = null;
    state.role = null;
    state.user = null;
  },
};

export default auth;
