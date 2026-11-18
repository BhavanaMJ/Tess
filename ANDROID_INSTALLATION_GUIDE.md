# TESS Android Setup, Compilation & Installation Guide

This guide provides step-by-step instructions for configuring an Android development environment, building the TESS Android APK, and installing it onto an Android emulator or physical device.

---

## 1. Prerequisites

- **Host OS**: Ubuntu Linux (or any Debian-based distribution / macOS / Windows with WSL2).
- **Flutter SDK**: 3.50.0+ (already installed at `/home/bhavanamj/flutter`).
- **Java Development Kit (JDK)**: OpenJDK 17 or 11 (`openjdk-17-jdk` recommended).
- **Storage**: ~5 GB free disk space for Android SDK, platform tools, and build caches.

---

## 2. Installing Android SDK Command-Line Tools (Headless / Terminal)

If Android Studio is not installed, the Android SDK can be installed entirely via the terminal:

### Step 2.1 — Install Java & Dependencies
```bash
sudo apt update
sudo apt install -y openjdk-17-jdk wget unzip adb
```

### Step 2.2 — Download and Extract Android Command-Line Tools
```bash
# Create SDK directory structure
mkdir -p $HOME/Android/Sdk/cmdline-tools

# Download official command-line tools (Linux)
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip cmdline-tools.zip
mkdir -p $HOME/Android/Sdk/cmdline-tools/latest
mv cmdline-tools/* $HOME/Android/Sdk/cmdline-tools/latest/
rm -rf cmdline-tools cmdline-tools.zip
```

### Step 2.3 — Configure Environment Variables
Add the following to your `~/.bashrc` (or `~/.zshrc`):
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
```
Then reload your shell:
```bash
source ~/.bashrc
```

### Step 2.4 — Install Platforms and Build Tools
```bash
# Accept licenses and install platform-tools, Android 34 platform, and build-tools
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Step 2.5 — Connect SDK to Flutter
```bash
flutter config --android-sdk $HOME/Android/Sdk
flutter doctor --android-licenses  # Press 'y' to accept all licenses
flutter doctor -v
```
You should now see `[✓] Android toolchain - develop for Android devices`.

---

## 3. Configuring the Backend Connection URL

In `flutter_app/lib/core/config/app_config.dart`, `AppConfig.resolveDefaultBackendUrl()` automatically detects the runtime platform:
- **Android Emulator**: `http://10.0.2.2:8000` (maps directly to host loopback `127.0.0.1:8000`).
- **Web / Desktop**: `http://127.0.0.1:8000`.
- **Physical Android Device**: Must connect to your workstation's local network IP (e.g. `http://192.168.1.50:8000`).

To specify a custom backend URL at build time or runtime:
```bash
flutter run --dart-define=API_URL=http://192.168.1.50:8000
```
Or build the APK with the defined backend endpoint:
```bash
flutter build apk --debug --dart-define=API_URL=http://192.168.1.50:8000
```

---

## 4. Building the Android Application Package (APK)

Navigate to the Flutter directory:
```bash
cd /home/bhavanamj/Desktop/Tess/flutter_app
```

### Debug Build (Recommended for Testing & Development)
```bash
flutter build apk --debug
```
Output artifact location:
`flutter_app/build/app/outputs/flutter-apk/app-debug.apk`

### Release Build (Optimized & Shrunk)
```bash
flutter build apk --release
```
Output artifact location:
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Installing the APK onto a Device or Emulator

### Method A — Installing via Android Debug Bridge (ADB)
1. Ensure your physical Android device has **Developer Options** and **USB Debugging** enabled, and connect it via USB.
2. Confirm the device is recognized:
   ```bash
   adb devices
   ```
3. Install the APK directly:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

### Method B — Running Directly from Flutter
To launch the app with live reload and console logging:
```bash
flutter run -d <device_id>
```

---

## 6. Verification Checklist on Device

Once the app is launched on Android:
1. **Login**: Enter Supabase credentials and tap **Authenticate Session**.
2. **Microphone Permission**: Navigate to Voice tab -> tap microphone -> allow Android runtime permission when prompted.
3. **Notification Permission**: Tap Register Device -> allow Android 13+ notification prompt.
4. **Dashboard**: Verify OpenProject metrics and Future Predictions load from FastAPI (`10.0.2.2:8000` or LAN IP).
5. **Agent Workflow**: Create an objective, approve a step requiring confirmation, and observe the live execution update.

