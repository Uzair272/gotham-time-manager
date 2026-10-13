import Vue from "vue";
import VueRouter from "vue-router";
import auth from "../auth";

import Home from "../components/Home.vue";
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

// meta.access:
//   "public"  -> anyone
//   "guest"   -> only when NOT signed in (sign in / sign up pages)
//   "private" -> signed-in users only
// meta.roles:  if set, only these roles can open the page
// meta.ownData: page about one user (:userid). Employees can only open their own.
const routes = [
  { path: "/", name: "home", component: Home, meta: { access: "public" } },
  { path: "/sign_in", name: "signIn", component: SignIn, meta: { access: "guest" } },
  { path: "/sign_up", name: "signUp", component: SignUp, meta: { access: "guest" } },
  { path: "/profile", name: "profile", component: Profile, meta: { access: "private" } },
  { path: "/teams", name: "teams", component: Teams, meta: { access: "private" } },
  {
    path: "/users",
    name: "users",
    component: Users,
    meta: { access: "private", roles: ["manager", "admin"] },
  },
  {
    path: "/workingTimes/:userID",
    name: "workingTimes",
    component: WorkingTimes,
    meta: { access: "private", ownData: "userID" },
  },
  {
    path: "/workingTime/:userid",
    name: "workingTimeCreate",
    component: WorkingTime,
    meta: { access: "private", ownData: "userid" },
  },
  {
    path: "/workingTime/:userid/:workingtimeid",
    name: "workingTimeEdit",
    component: WorkingTime,
    meta: { access: "private", ownData: "userid" },
  },
  {
    path: "/clock/:userid",
    name: "clock",
    component: ClockManager,
    meta: { access: "private", ownData: "userid" },
  },
  {
    path: "/chartManager/:userid",
    name: "chartManager",
    component: ChartManager,
    meta: { access: "private", ownData: "userid" },
  },
  { path: "*", redirect: "/" },
];

const router = new VueRouter({
  mode: "history",
  routes,
});

// Navigation guard: runs before EVERY page change.
// Always call next(...) exactly once, otherwise the navigation never finishes.
router.beforeEach((to, from, next) => {
  const access = to.meta.access || "private";

  if (access === "public") {
    return next();
  }

  if (access === "guest") {
    return auth.isLoggedIn() ? next("/") : next();
  }

  // Private page: you must be signed in
  if (!auth.isLoggedIn()) {
    return next({ path: "/sign_in", query: { redirect: to.fullPath } });
  }

  // Page restricted to some roles
  if (to.meta.roles && !auth.hasRole(...to.meta.roles)) {
    return next("/");
  }

  // Employees can only open their own clock / working times / charts
  const param = to.meta.ownData;
  if (param && auth.hasRole("employee") && String(to.params[param]) !== String(auth.state.userId)) {
    return next({ name: to.name, params: { ...to.params, [param]: auth.state.userId } });
  }

  return next();
});

export default router;
