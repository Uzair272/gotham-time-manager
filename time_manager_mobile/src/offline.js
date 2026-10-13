import Vue from "vue";
import Loki from "lokijs";
import { Network } from "@capacitor/network";
import api from "./api";
import { toast } from "./native";

/*
 * OFFLINE MODE
 * 1. CACHE: a LokiJS NoSQL database saved in the phone's local storage.
 *    Every GET answer is saved; offline, pages read from it.
 *    Online, the server has priority: API first, then the cache is updated.
 * 2. QUEUE: a FIFO list (First In, First Out) in localStorage, as JSON strings.
 *    Changes made offline are stored in order and replayed when back online.
 */

// Reactive state used by the UI (offline banner, spinner)
export const net = Vue.observable({
  online: true,
  syncing: false,
  pending: 0, // number of changes waiting in the queue
  syncCount: 0, // +1 after each sync -> pages reload their data
  message: "",
  nativeSpinner: false,
});

// A network error = no answer at all (offline, API down).
// An API error (401, 403, 422...) is a real answer: it has err.response.
const isNetworkError = (err) => !err.response;

// ================= 1. CACHE (LokiJS) =================

const db = new Loki("gotham.db", { autosave: true, autosaveInterval: 1000 });

// The database loads from storage asynchronously: wait for it before using it
const dbReady = new Promise((resolve) => {
  db.loadDatabase({}, () => {
    if (!db.getCollection("cache")) {
      // One document per API url: { url: "/clocks/3", body: { data: [...] } }
      // The url is unique, so each piece of data is stored once (no duplicates)
      db.addCollection("cache", { unique: ["url"] });
    }
    resolve();
  });
});

async function cacheCollection() {
  await dbReady;
  return db.getCollection("cache");
}

export async function cacheSet(url, body) {
  const cache = await cacheCollection();
  const doc = cache.by("url", url);
  if (doc) {
    doc.body = body;
    cache.update(doc);
  } else {
    cache.insert({ url, body });
  }
}

async function cacheGet(url) {
  const cache = await cacheCollection();
  const doc = cache.by("url", url);
  return doc ? doc.body : null;
}

async function clearCache() {
  const cache = await cacheCollection();
  cache.findAndRemove({});
}

// GET: server first, cache as fallback.
// Returns the same shape as axios ({ data: body }),
// so in the pages we can simply replace api.get(...) with cachedGet(...)
export async function cachedGet(url) {
  if (net.online) {
    try {
      const response = await api.get(url);
      await cacheSet(url, response.data); // keep the local copy up to date
      return { data: response.data, fromCache: false };
    } catch (err) {
      if (!isNetworkError(err)) throw err;
      // no answer -> fall back to the cache below
    }
  }
  const body = await cacheGet(url);
  if (body === null) {
    throw new Error("Offline and no saved data for " + url);
  }
  return { data: body, fromCache: true };
}

// ================= 2. QUEUE (FIFO in localStorage) =================

const QUEUE_KEY = "offlineQueue";

// localStorage only stores strings -> JSON.stringify / JSON.parse
function readQueue() {
  return JSON.parse(localStorage.getItem(QUEUE_KEY) || "[]");
}

function writeQueue(queue) {
  localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
  net.pending = queue.length;
}

// POST/PUT/DELETE: send now if online, otherwise add to the END of the queue.
// applyLocally(): updates the cache/page so the user sees the change immediately.
export async function send(method, url, body, applyLocally) {
  if (net.online) {
    try {
      const response = await api.request({ method, url, data: body });
      return { queued: false, data: response.data };
    } catch (err) {
      if (!isNetworkError(err)) throw err;
      // the API didn't answer -> treat it as offline and queue it
    }
  }
  const queue = readQueue();
  queue.push({ method, url, body, createdAt: new Date().toISOString() });
  writeQueue(queue);
  if (applyLocally) await applyLocally();
  return { queued: true };
}

// ================= SYNC =================

// Native spinner dialog (cordova-plugin-progress-indicator)
function showSpinner() {
  if (window.ProgressIndicator) {
    window.ProgressIndicator.showSimpleWithLabel(true, "Syncing offline changes...");
    return true;
  }
  return false; // plugin not available (e.g. in a browser): the app shows its own overlay
}

function hideSpinner() {
  if (window.ProgressIndicator) {
    window.ProgressIndicator.hide();
  }
}

let running = false;

export async function sync() {
  if (running || !net.online || readQueue().length === 0) return;
  running = true;
  net.syncing = true;
  net.nativeSpinner = showSpinner();

  try {
    // First In, First Out: always send the OLDEST change first
    while (readQueue().length > 0) {
      const [oldest, ...rest] = readQueue();
      await api.request({ method: oldest.method, url: oldest.url, data: oldest.body });
      writeQueue(rest); // removed only once the server accepted it
    }
    net.message = "Offline changes synced";
  } catch (err) {
    if (isNetworkError(err)) {
      // Connection lost again: keep the remaining changes for next time
      net.message = "Connection lost during sync. Will retry.";
    } else {
      // The server refused a change: cancel everything, the server's data wins
      writeQueue([]);
      await clearCache();
      net.message = "Some offline changes were refused. Data reloaded from the server.";
    }
  } finally {
    hideSpinner();
    if (net.message) toast(net.message); // native toast with the sync result
    net.syncing = false;
    net.syncCount += 1; // pages reload fresh data from the server
    running = false;
    setTimeout(() => (net.message = ""), 4000);
  }
}

// Called once at app start (main.js)
export async function initOffline() {
  net.pending = readQueue().length;

  const status = await Network.getStatus();
  net.online = status.connected;

  // Native event: fires when the phone goes online/offline
  Network.addListener("networkStatusChange", (s) => {
    net.online = s.connected;
    if (s.connected) sync(); // back online -> send the queue
  });

  // Also retry every 30 s (e.g. if the API itself was down)
  setInterval(sync, 30000);
  sync();
}

// On logout: don't leave this user's data on the phone
export async function resetOffline() {
  writeQueue([]);
  await clearCache();
}