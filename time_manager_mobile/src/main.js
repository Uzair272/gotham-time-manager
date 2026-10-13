import Vue from "vue";
import App from "./App.vue";
import router from "./router";
import auth from "./auth";
import { setUnauthorizedHandler } from "./api";
import { initOffline } from "./offline";
import { setupStatusBar } from "./native";

Vue.config.productionTip = false;

// The API said 401: the session is over -> forget it and go to sign in
setUnauthorizedHandler(() => {
  auth.clear();
  if (router.currentRoute.path !== "/sign_in") {
    router.push({ path: "/sign_in", query: { redirect: router.currentRoute.fullPath } });
  }
});

// Native status bar colour
setupStatusBar();

// Start watching the network and send any queued changes
initOffline();

// Already signed in from a previous visit: refresh the user (works offline from the cache)
if (auth.isLoggedIn()) {
  auth.refresh().catch(() => {});
}

new Vue({
  router,
  render: (h) => h(App),
}).$mount("#app");