import Vue from "vue";
import VueRouter from "vue-router";
import WorkingTimes from "../components/WorkingTimes.vue";
import WorkingTime from "../components/WorkingTime.vue";
import ClockManager from "../components/ClockManager.vue";
import ChartManager from "../components/ChartManager.vue";

Vue.use(VueRouter);

const routes = [
  {
    path: "/workingTimes/:userID",
    name: "workingTimes",
    component: WorkingTimes,
  },
  {
    path: "/workingTime/:userid",
    name: "workingTimeCreate",
    component: WorkingTime,
  },
  {
    path: "/workingTime/:userid/:workingtimeid",
    name: "workingTimeEdit",
    component: WorkingTime,
  },
  {
    path: "/clock/:userid",
    name: "clock",
    component: ClockManager,
  },
  {
    path: "/chartManager/:userid",
    name: "chartManager",
    component: ChartManager,
  },
];

const router = new VueRouter({
  mode: "history",
  routes,
});

export default router;