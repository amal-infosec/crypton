# 🛡️ Crypton

**Crypton** is a high-performance, ultra-secure password and notes manager designed for Android, Windows, and Linux. Featuring a stunning "Liquid Glass" glassmorphism aesthetic and robust encryption, Crypton provides a premium, zero-knowledge experience for managing your digital identity.

---

## ✨ Pro Features

- **Zero-Knowledge Architecture**: Secure your sensitive data using industry-standard AES-256 encryption. Your master password is never stored on disk; it is used only to derive the encryption key in volatile memory during your session.
- **Stealth Mode (Duress PIN)**: Create a secondary "fake" password that opens an empty or safe-for-work vault. Perfect for situations where you are forced to unlock the app. Global stealth access applies to all areas of the app.
- **Secure Media Vault**: Import, encrypt, and view sensitive photos and videos directly within the app without leaving traces on your local storage. Protected by a separate PIN or biometric lock.
- **Extensive Import/Export**: Import your passwords from major managers including 1Password, Bitwarden, Chrome, Dashlane, Firefox, LastPass, Safari, and more. Features a robust cross-desktop fallback for seamless importing on Windows and Linux.
- **Biometric Authentication**: Quick access using your device's native biometric hardware (Android Fingerprint, Windows Hello, Linux Biometrics).
- **Liquid Glass UI**: A modern, premium aesthetic with deep gradients, dynamic frosted glass effects, and seamless cross-platform animations.
- **Hardened Android Security**: Leverages system-level protections (`FLAG_SECURE`) to prevent background snapshots, screen recording, and unauthorized screen capturing.
- **Privacy-First (Zero Telemetry)**: Your data stays local. No cloud storage, no analytics, no telemetry.

---

## 🚀 Getting Started

### Android
1. **Download the APK**: Navigate to `build/app/outputs/flutter-apk/app-release.apk`.
2. **Install**: Transfer the APK to your device and install it (ensure "Install from Unknown Sources" is enabled).
3. **Run**: Launch "Crypton" from your app drawer.

### Windows
1. **Download the MSIX Installer**: Navigate to `build/windows/x64/runner/Release/crypton.msix`.
2. **Install**: Double-click the installer and follow the prompts.
3. **Run**: Launch "Crypton" from your Start Menu.

### Linux (Arch Linux / Hyprland)

#### 🚀 Automated Install (Recommended)
This method is optimized for **Hyprland/Wayland** and sets up your app launcher automatically.
1. **Download**: Get `crypton-linux.zip` from your GitHub repository's **Actions** tab.
2. **Install**:
   ```bash
   unzip crypton-linux.zip -d crypton-app
   cd crypton-app
   ./install.sh
   ```
3. **Launch**: Search for **"Crypton"** in your launcher (`wofi`, `rofi`, `tofi`, etc.).

#### 🛠️ Manual Install
1. **Prerequisites (Arch Linux)**: `sudo pacman -S --needed gtk3 libsecret xdg-desktop-portal-gtk alsa-lib libasound mpv`
2. **Prerequisites (Debian/Ubuntu)**: `sudo apt-get install libgtk-3-dev libsecret-1-dev libasound2-dev libmpv-dev`
3. **Setup**:
   - Extract the binary bundle to a permanent folder.
   - Make the binary executable: `chmod +x crypton`
4. **Wayland Support**: To run natively on Wayland, use:
   ```bash
   GDK_BACKEND=wayland ./crypton
   ```
5. **Shortcut**: Copy the `crypton.desktop` file to `~/.local/share/applications/` and edit the `Exec` line to point to your binary's full path.

---

## 🛠️ Development

### Build Prerequisites (Linux)
To build the Linux version, you must install the following development packages:
- **Arch Linux**: `sudo pacman -S --needed base-devel cmake pkg-config gtk3 libsecret alsa-lib mpv`
- **Debian/Ubuntu**: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libasound2-dev libmpv-dev`

### Build Commands
- **Android Release (APK)**: `flutter build apk --release`
- **Windows Release**: `flutter build windows --release`
- **Linux Release**: `flutter build linux --release`
- **Installer (Windows)**: `dart run msix:create`

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying is strictly prohibited.
