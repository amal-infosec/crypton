# 🛡️ Crypton

**Crypton** is a high-performance, ultra-secure password and notes manager designed for Windows and Linux. Featuring a stunning "Liquid Glass" glassmorphism aesthetic and robust encryption, Crypton provides a premium experience for managing your digital identity.

---

## ✨ Features

- **Liquid Glass UI**: A modern, premium aesthetic with deep gradients and dynamic frosted glass effects.
- **Robust Encryption**: Secure your sensitive data using industry-standard AES-256 encryption.
- **Biometric Authentication**: Quick access using your system's biometric hardware (Windows Hello / Linux Biometrics).
- **Multi-Platform Support**: Optimized for high performance on Android, Windows 11, and Linux environments.
- **Privacy-First**: Your data stays local. No cloud storage, no telemetry.

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
1. **Download**: Get `crypton-linux.zip` from Your GitHub repository's **Actions** tab.
2. **Install**:
   ```bash
   unzip crypton-linux.zip -d crypton-app
   cd crypton-app
   ./install.sh
   ```
3. **Launch**: Search for **"Crypton"** in your launcher (`wofi`, `rofi`, `tofi`, etc.).

#### 🛠️ Manual Install
1. **Prerequisites (Arch Linux)**: `sudo pacman -S --needed gtk3 libsecret xdg-desktop-portal-gtk alsa-lib libasound`
2. **Prerequisites (Debian/Ubuntu)**: `sudo apt-get install libgtk-3-dev libsecret-1-dev libasound2-dev`
3. **Setup**:
   - Extract the binary bundle to a permanent folder.
   - Make the binary executable: `chmod +x crypton`
3. **Wayland Support**: To run natively on Wayland, use:
   ```bash
   GDK_BACKEND=wayland ./crypton
   ```
4. **Shortcut**: Copy the `crypton.desktop` file to `~/.local/share/applications/` and edit the `Exec` line to point to your binary's full path.
5. **Import/Export**: If the file picker fails, the app provides a manual path entry fallback. For a seamless experience, ensure `xdg-desktop-portal-gtk` (or equivalent) is installed and active.

---

## 🛠️ Development

### Build Prerequisites (Linux)
To build the Linux version, you must install the following development packages:
- **Arch Linux**: `sudo pacman -S --needed base-devel cmake pkg-config gtk3 libsecret alsa-lib`
- **Debian/Ubuntu**: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libasound2-dev`

### Build Commands
- **Android Release (APK)**: `flutter build apk --release`
- **Windows Release**: `flutter build windows --release`
- **Linux Release**: `flutter build linux --release`
- **Installer (Windows)**: `flutter pub run msix:create`

---

## 🔒 Security

Crypton follows the principle of zero-knowledge architecture. Your master password is never stored on disk; it is used only to derive the encryption key in volatile memory during your session.

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
