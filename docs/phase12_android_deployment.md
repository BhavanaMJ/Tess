# TESS Phase 12 — Android Personal Deployment Guide

**Date:** November 16, 2026  
**Framework:** React Native 0.76.7 + Expo SDK 52  
**Target Package:** Sideloadable Android APK (`ai.tess.companion`)  
**Status:** CONFIGURATION READY / LOCAL APK BUILD PROCEDURE DOCUMENTED

---

## 1. Application Configuration

The mobile application configuration has been upgraded in [mobile/app.json](file:///home/bhavanamj/Desktop/Tess/mobile/app.json) and [mobile/eas.json](file:///home/bhavanamj/Desktop/Tess/mobile/eas.json):

### App Identifiers & Metadata:
- **Application Name:** `TESS - Personal AI Companion`
- **Application ID (Package):** `ai.tess.companion`
- **Version:** `1.0.0` (versionCode `1`)
- **Theme:** Dark theme (`#0A0A0F`) matching Desktop mascot palette.
- **Permissions Declared:**
  - `RECORD_AUDIO`: Voice assistant recording.
  - `INTERNET`: Secure HTTPS/WSS communication with FastAPI backend and Supabase.
  - `ACCESS_NETWORK_STATE`: Network interruption and offline reconnection detection.
  - `POST_NOTIFICATIONS`: Android 13+ push and local routine notifications.

---

## 2. Installable APK Generation Procedure

To generate a real `.apk` installer file for personal sideloading on your physical Android phone (without publishing to Google Play Store):

### Method A: Cloud EAS Build (Recommended for Quick Standalone APK)
```bash
cd mobile

# 1. Log in to your personal Expo account (free tier)
npx eas-cli login

# 2. Configure EAS project ID
npx eas-cli project:init

# 3. Build standalone APK
npx eas-cli build --platform android --profile preview
```
*Output:* Provides a direct `.apk` download URL that can be downloaded onto your phone or sideloaded.

### Method B: Local Gradle APK Build
If an Android SDK and Android Build Tools (Platform 34) are installed locally:
```bash
cd mobile

# 1. Generate native Android project files
npx expo prebuild --platform android --clean

# 2. Compile release APK
cd android
./gradlew assembleRelease

# 3. Locate generated APK:
# android/app/build/outputs/apk/release/app-release.apk
```

---

## 3. Physical Device Sideloading Instructions

Once the `.apk` file is generated:

### Option 1: Via ADB (USB Debugging)
```bash
# Enable Developer Options & USB Debugging on your phone, then:
adb install -r app-release.apk
```

### Option 2: Direct File Transfer
1. Transfer the `.apk` to your phone via USB cable, Google Drive, or local HTTP server.
2. Open the file on your device and tap **Install**.
3. If prompted, toggle **Allow from this source**.

---

## 4. Mobile Runtime Capabilities & Verification Matrix

| Capability | Implementation File | Verification Status | Notes |
| :--- | :--- | :--- | :--- |
| **Authentication & Session** | `mobile/lib/supabase.ts` | **VERIFIED** | Supabase JWT stored in AsyncStorage; auto-refreshes token. |
| **Network Timeout & Retry** | `mobile/services/api.ts` | **VERIFIED** | 15s `fetchWithTimeout` with `AbortController`. |
| **Chat & Memory Sync** | `mobile/screens/HomeScreen.tsx` | **VERIFIED** | Interacts with `/api/v1/conversations`. |
| **Futures & Simulation** | `mobile/screens/FutureScreen.tsx` | **VERIFIED** | Visualizes 24h trajectory and probability. |
| **Proactive Interventions** | `mobile/screens/InterventionsScreen.tsx` | **VERIFIED** | Dispatches `CONFIRM`, `LATER`, `DISMISS`. |
| **Living Companion Mascot** | `mobile/components/Mascot.tsx` | **VERIFIED** | SVG facial animations (`IDLE`, `THINKING`, `HAPPY`). |
| **Microphone / Voice** | `RECORD_AUDIO` permission | **CONFIGURED** | Ready for voice recording; requires physical microphone to test audio input. |
| **Physical Sideload Test** | On-device execution | **BLOCKED** | Host environment lacks connected physical phone & ADB. |

