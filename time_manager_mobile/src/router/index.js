import Vue from "vue";
import VueRouter from "vue-router";
import auth from "../auth";

import SignIn from "../components/SignIn.vue";
import SignUp from "../components/SignUp.vue";
import Profile from "../components/Profile.vue";
import Users from "../components/Users.vue";
import Teams from "../components/Teams.vue";
import WorkingTimes from "../components/WorkingTimes.vue";
import WorkingTime from "../components/WorkingTime.vue";
import ClockManager from "../components/ClockManager.vue";
import ChartManager from "../components/ChartManager.vue";

Vue.use(VueRouter);

// meta.access:  "guest" (logged out only) or "private" (logged in)
// meta.roles:   only these roles
// meta.ownData: employees can only open their own :userid
// meta.title:   shown in the top bar
// meta.sub:     sub-page -> back button, no tab of its own
const routes = [
  // Home: logged in -> Clock page, otherwise -> sign in
  {
    path: "/",
    redirect: () => (auth.isLoggedIn() ? "/clock/" + auth.state.userId : "/sign_in"),
  },
  { path: "/sign_in", component: SignIn, meta: { access: "guest" } },
  { path: "/sign_up", component: SignUp, meta: { access: "guest" } },
  { path: "/profile", component: Profile, meta: { access: "private", title: "Profile" } },
  { path: "/teams", component: Teams, meta: { access: "private", title: "Teams" } },
  {
    path: "/users",
    component: Users,
    meta: { access: "private", roles: ["manager", "admin"], title: "Users" },
  },
  {
    path: "/clock/:userid",
    name: "clock",
    component: ClockManager,
    meta: { access: "private", ownData: "userid", title: "Clock" },
  },
  {
    path: "/workingTimes/:userID",
    name: "workingTimes",
    component: WorkingTimes,
    meta: { access: "private", ownData: "userID", title: "Working times" },
  },
  {
    path: "/workingTime/:userid",
    name: "workingTimeCreate",
    component: WorkingTime,
    meta: { access: "private", ownData: "userid", title: "New entry", sub: true },
  },
  {
    path: "/workingTime/:userid/:workingtimeid",
    name: "workingTimeEdit",
    component: WorkingTime,
    meta: { access: "private", ownData: "userid", title: "Edit entry", sub: true },
  },
  // Dashboard: not required on mobile, kept as a sub-page (no tab)
  {
    path: "/chartManager/:userid",
    name: "chartManager",
    component: ChartManager,
    meta: { access: "private", ownData: "userid", title: "Charts", sub: true },
  },
  { path: "*", redirect: "/" },
];

const router = new VueRouter({
  mode: "history",
  routes,
});

// Same guard as the website
router.beforeEach((to, from, next) => {
  const access = to.meta.access || "private";

  if (access === "guest") {
    return auth.isLoggedIn() ? next("/") : next();
  }

  if (!auth.isLoggedIn()) {
    return next({ path: "/sign_in", query: { redirect: to.fullPath } });
  }

  if (to.meta.roles && !auth.hasRole(...to.meta.roles)) {
    return next("/");
  }

  const param = to.meta.ownData;
  if (param && auth.hasRole("employee") && String(to.params[param]) !== String(auth.state.userId)) {
    return next({ name: to.name, params: { ...to.params, [param]: auth.state.userId } });
  }

  return next();
});

export default router;