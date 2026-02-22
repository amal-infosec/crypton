#!/bin/bash
# Install Crypton for Arch Linux (Hyprland/Wayland)

# Standard Linux install paths
INSTALL_DIR="$HOME/.local/share/crypton-app"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"

echo "🛡️ Installing Crypton to $INSTALL_DIR..."

# 1. Create Directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$ICON_DIR"

# 2. Copy App Files (Assuming run from inside the extracted zip)
cp -r ./* "$INSTALL_DIR/"

# 3. Create Binary Wrapper with Wayland support
cat <<EOF > "$BIN_DIR/crypton"
#!/bin/bash
# Force Wayland backend for Hyprland
env GDK_BACKEND=wayland "$INSTALL_DIR/crypton" "\$@"
EOF
chmod +x "$BIN_DIR/crypton"

# 4. Install Desktop Entry
cp "$INSTALL_DIR/linux/crypton.desktop" "$APP_DIR/"
cp "$INSTALL_DIR/linux/uninstall.sh" "$BIN_DIR/crypton-uninstall"
chmod +x "$BIN_DIR/crypton-uninstall"

# 5. Install Icon
# Note: Falling back to flutter_assets path if direct icon isn't found
if [ -f "data/flutter_assets/assets/icon/icon.png" ]; then
    cp "data/flutter_assets/assets/icon/icon.png" "$ICON_DIR/crypton.png"
    # Also link to generic icons folder for better launcher compatibility
    cp "data/flutter_assets/assets/icon/icon.png" "$HOME/.local/share/icons/crypton.png"
fi

echo "✅ Installation complete!"
echo "🚀 You can now find 'Crypton' in your app launcher (wofi/rofi/tofi/etc.)"
echo "💡 Note: Make sure $BIN_DIR is in your PATH."
