import { isPermissionGranted, requestPermission, sendNotification } from '@tauri-apps/plugin-notification';
import { NotificationSettings } from '../types';

const SETTINGS_KEY = 'tess_notification_settings';
const DEFAULT_SETTINGS: NotificationSettings = {
  enabled: true,
  futureRisks: true,
  deadlines: true,
  interventions: true,
  agentResults: true,
  detailedPreviews: true
};

export const getNotificationSettings = (): NotificationSettings => {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    return raw ? { ...DEFAULT_SETTINGS, ...JSON.parse(raw) } : DEFAULT_SETTINGS;
  } catch {
    return DEFAULT_SETTINGS;
  }
};

export const saveNotificationSettings = (settings: NotificationSettings) => {
  try {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
  } catch {}
};

// Deduplication cache
const recentNotifications = new Set<string>();

export const notifyDesktop = async (
  title: string,
  body: string,
  category: 'futureRisks' | 'deadlines' | 'interventions' | 'agentResults' = 'interventions'
) => {
  const settings = getNotificationSettings();
  if (!settings.enabled || !settings[category]) {
    return;
  }

  // Deduplication key
  const key = `${title}:${body}`;
  if (recentNotifications.has(key)) {
    return;
  }
  recentNotifications.add(key);
  setTimeout(() => recentNotifications.delete(key), 60000); // 1 minute cooldown

  // Mask private details if previews disabled
  const displayBody = settings.detailedPreviews
    ? body
    : 'TESS has an update requiring your attention.';

  try {
    // 1. Try Tauri native notification
    let permissionGranted = await isPermissionGranted();
    if (!permissionGranted) {
      const permission = await requestPermission();
      permissionGranted = permission === 'granted';
    }
    if (permissionGranted) {
      sendNotification({ title: `🐾 ${title}`, body: displayBody });
      return;
    }
  } catch (_) {
    // Fallback to Web Notification API if available
    try {
      if (typeof window !== 'undefined' && 'Notification' in window) {
        if (Notification.permission === 'granted') {
          new Notification(`🐾 ${title}`, { body: displayBody });
        } else if (Notification.permission !== 'denied') {
          const res = await Notification.requestPermission();
          if (res === 'granted') {
            new Notification(`🐾 ${title}`, { body: displayBody });
          }
        }
      }
    } catch (_) {}
  }
};

