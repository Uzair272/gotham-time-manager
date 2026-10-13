import Vue from "vue";
import App from "./App.vue";
import router from "./router";
import auth from "./auth";
import { setUnauthorizedHandler } from "./api";

Vue.config.productionTip = false;

// The API said 401: the session is over -> forget it and go to the sign-in page
setUnauthorizedHandler(() => {
  auth.clear();
  if (router.currentRoute.path !== "/sign_in") {
    router.push({ path: "/sign_in", query: { redirect: router.currentRoute.fullPath } });
  }
});

// Already signed in from a previous visit: refresh the user (and their role)
if (auth.isLoggedIn()) {
  auth.refresh().catch(() => {});
}

new Vue({
  router,
  render: (h) => h(App),
}).$mount("#app");
