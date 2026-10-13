<template>
  <div>
    <!-- Offline banner -->
    <div v-if="!net.online" class="banner offline">
      You're offline. Showing saved data.
      <span v-if="net.pending"> {{ net.pending }} change(s) waiting.</span>
    </div>

    <!-- Online but changes still waiting (e.g. API was down) -->
    <div v-else-if="net.pending && !net.syncing" class="banner pending">
      {{ net.pending }} change(s) waiting to sync
    </div>

    <!-- Result of the last sync (tap to hide) -->
    <div v-if="net.message" class="banner info" @click="net.message = ''">
      {{ net.message }}
    </div>

    <!-- Fallback spinner, only if the native one isn't available -->
    <div v-if="net.syncing && !net.nativeSpinner" class="overlay">
      <div class="spinner"></div>
      <p>Syncing offline changes...</p>
    </div>
  </div>
</template>

<script>
import { net } from "../offline";

export default {
  name: "OfflineBanner",
  data() {
    return { net };
  },
};
</script>

<style scoped>
.banner {
  padding: 10px 16px;
  font-size: 14px;
  font-weight: 600;
  text-align: center;
}
.offline {
  background: #1f2937;
  color: #fbbf24;
}
.pending {
  background: #fef3c7;
  color: #92400e;
}
.info {
  background: #d1fae5;
  color: #065f46;
}
.overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: rgba(15, 23, 42, 0.6);
  color: #fff;
}
.spinner {
  width: 48px;
  height: 48px;
  border: 5px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>