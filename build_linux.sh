#!/bin/bash
# 🛡️ Crypton Linux Build & Install Script
# This script automates the process of building Crypton from source on Linux.

set -e

echo "🛡️  Starting Crypton Linux Build..."

# 1. Detect OS and Install Dependencies
if [ -f /etc/arch-release ]; then
    echo "📦 Detected Arch Linux. Installing dependencies..."
    sudo pacman -Sy --needed --noconfirm clang cmake ninja pkg-config gtk3 xz libsecret jsoncpp zip
elif [ -f /etc/debian_version ]; then
    echo "📦 Detected Debian/Ubuntu. Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev zip
else
    echo "⚠️  Distribution not explicitly supported for auto-dependency install."
    echo "Please ensure you have: clang, cmake, ninja, pkg-config, lzma, libsecret, and jsoncpp."
fi

# 2. Verify Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in your PATH."
    echo "Download it from: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

# 3. Configure & Build
echo "⚙️  Configuring Flutter..."
flutter config --enable-linux-desktop

echo "🔍 Fetching dependencies..."
flutter pub get

echo "⚒️  Building Release Binary..."
flutter build linux --release

# 4. Prepare Bundle for Installation
echo "📦 Preparing installation bundle..."
BUNDLE_DIR="build/linux/x64/release/bundle"
mkdir -p "$BUNDLE_DIR/linux"
cp linux/crypton.desktop "$BUNDLE_DIR/linux/"
cp linux/uninstall.sh "$BUNDLE_DIR/linux/"
cp linux/install.sh "$BUNDLE_DIR/"

# 5. Offer Installation
echo ""
echo "✅ Build Complete!"
read -p "🚀 Would you like to install Crypton to your system now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "💾 Running installer..."
    cd "$BUNDLE_DIR"
    bash ./install.sh
else
    echo "📂 You can find the build at: $BUNDLE_DIR"
fi
