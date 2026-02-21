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

### Linux (Arch Linux)
1. **Prepare Dependencies**:
   ```bash
   sudo pacman -S --needed flutter-sdk-bin clang cmake ninja pkg-config gtk3 libsecret
   ```
2. **Build the Binary**:
   ```bash
   flutter build linux --release
   ```
3. **Run the App**: `./build/linux/x64/release/bundle/crypton`

---

## 🛠️ Development

### Prerequisites
- Flutter SDK (3.10.7 or later)
- Visual Studio (for Windows builds)
- Clang/C++ tools (for Linux builds)

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
