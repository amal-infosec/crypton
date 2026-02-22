#!/bin/bash
# Uninstall Crypton

INSTALL_DIR="$HOME/.local/share/crypton-app"
BIN_FILE="$HOME/.local/bin/crypton"
APP_FILE="$HOME/.local/share/applications/crypton.desktop"
ICON_FILE1="$HOME/.local/share/icons/hicolor/512x512/apps/crypton.png"
ICON_FILE2="$HOME/.local/share/icons/crypton.png"

echo "🗑️ Removing Crypton..."

rm -rf "$INSTALL_DIR"
rm -f "$BIN_FILE"
rm -f "$APP_FILE"
rm -f "$ICON_FILE1"
rm -f "$ICON_FILE2"

echo "✅ Uninstallation complete!"
