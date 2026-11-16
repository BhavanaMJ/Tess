import '@testing-library/jest-dom/vitest';
import { vi } from 'vitest';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString();
    },
    removeItem: (key: string) => {
      delete store[key];
    },
    clear: () => {
      store = {};
    }
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock
});

// Mock BroadcastChannel with full EventTarget interface for Supabase auth-js
class MockBroadcastChannel {
  name: string;
  onmessage: ((event: any) => void) | null = null;
  constructor(name: string) {
    this.name = name;
  }
  postMessage(message: any) {}
  close() {}
  addEventListener(event: string, callback: any) {}
  removeEventListener(event: string, callback: any) {}
  dispatchEvent(event: any) {
    return true;
  }
}

(window as any).BroadcastChannel = MockBroadcastChannel;

// Mock Tauri API core
vi.mock('@tauri-apps/api/core', () => ({
  invoke: vi.fn().mockImplementation((cmd: string, args: any) => {
    if (cmd === 'get_desktop_platform') return Promise.resolve('linux');
    if (cmd === 'focus_main_window') return Promise.resolve();
    if (cmd === 'toggle_mascot_window') return Promise.resolve();
    if (cmd === 'set_mascot_position') return Promise.resolve();
    if (cmd === 'get_mascot_position') return Promise.resolve([1720, 820]);
    return Promise.resolve();
  })
}));

// Mock Tauri webviewWindow API
vi.mock('@tauri-apps/api/webviewWindow', () => ({
  WebviewWindow: {
    getByLabel: vi.fn().mockResolvedValue({
      show: vi.fn(),
      unminimize: vi.fn(),
      setFocus: vi.fn(),
    }),
  },
}));

export const mockSendNotification = vi.fn();

// Mock Tauri Notification plugin
vi.mock('@tauri-apps/plugin-notification', () => ({
  isPermissionGranted: vi.fn().mockResolvedValue(true),
  requestPermission: vi.fn().mockResolvedValue('granted'),
  sendNotification: (...args: any[]) => mockSendNotification(...args)
}));
