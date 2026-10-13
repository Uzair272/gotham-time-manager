import axios from "axios";

// One axios instance for the whole app.
// withCredentials: true -> the browser sends the HttpOnly JWT cookie with every request.
const api = axios.create({
  baseURL: process.env.VUE_APP_API_URL || "http://localhost:4000/api",
  withCredentials: true,
});

// Every request carries the xsrf token in the x-xsrf-token header.
// The API compares it with the one stored inside the JWT cookie.
api.interceptors.request.use((config) => {
  const xsrfToken = localStorage.getItem("xsrfToken");
  if (xsrfToken) {
    config.headers["x-xsrf-token"] = xsrfToken;
  }
  return config;
});

// If the API answers 401 (not signed in / session expired), let the app react
// (main.js clears the session and sends the user to /sign_in).
let onUnauthorized = null;

export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler;
}

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response && error.response.status;
    const url = (error.config && error.config.url) || "";
    if (status === 401 && onUnauthorized && !url.includes("/users/sign_in")) {
      onUnauthorized();
    }
    return Promise.reject(error);
  }
);

export default api;
