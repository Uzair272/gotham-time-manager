import { Capacitor } from "@capacitor/core";
import { Dialog } from "@capacitor/dialog";
import { Haptics, ImpactStyle } from "@capacitor/haptics";
import { Toast } from "@capacitor/toast";
import { StatusBar, Style } from "@capacitor/status-bar";

/*
 * NATIVE FEATURES
 * Each function calls a Capacitor plugin, which talks to Android directly.
 * In a browser the plugins fall back to web versions, so nothing breaks.
 */

export const isNative = Capacitor.isNativePlatform();

// Native confirm dialog -> true (OK) or false (Cancel)
export async function confirmDialog(title, message, okText = "OK") {
  const { value } = await Dialog.confirm({
    title,
    message,
    okButtonTitle: okText,
    cancelButtonTitle: "Cancel",
  });
  return value;
}

// Native prompt dialog with one text field -> the text, or null if cancelled
export async function promptDialog(title, message, placeholder, okText = "OK") {
  const { value, cancelled } = await Dialog.prompt({
    title,
    message,
    inputPlaceholder: placeholder,
    okButtonTitle: okText,
    cancelButtonTitle: "Cancel",
  });
  return cancelled ? null : (value || "").trim();
}

// Short vibration (haptic feedback) to confirm an important action
export async function vibrate() {
  try {
    await Haptics.impact({ style: ImpactStyle.Medium });
  } catch (e) {
    // not supported (e.g. browser): ignore
  }
}

// Native toast message at the bottom of the screen
export async function toast(text) {
  try {
    await Toast.show({ text, duration: "short", position: "bottom" });
  } catch (e) {
    // ignore
  }
}

// Status bar in the app's colour, with light icons
export async function setupStatusBar() {
  if (!isNative) return;
  try {
    await StatusBar.setBackgroundColor({ color: "#1e3a8a" });
    await StatusBar.setStyle({ style: Style.Dark });
  } catch (e) {
    // ignore
  }
}