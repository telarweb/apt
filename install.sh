#!/bin/bash
set -e

# TelarWeb One-Line Installer
# Usage: curl -fsSL https://telarweb.github.io/apt/install.sh | sudo bash

# Configuration
REPO_URL="https://telarweb.github.io/apt"
KEYRING_PATH="/usr/share/keyrings/telarweb-archive-keyring.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/telarweb.list"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TelarWeb Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Raspberry Pi WiFi Provisioning via BLE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Please run: sudo bash install.sh"
    exit 1
fi

# Check if running on Raspberry Pi OS
if [ ! -f /etc/rpi-issue ]; then
    echo "Warning: This script is designed for Raspberry Pi OS"
    # Read from the terminal, not stdin: when run via `curl | bash`,
    # stdin is the script itself and `read` would swallow script lines.
    if read -p "Continue anyway? (y/N) " -n 1 -r </dev/tty 2>/dev/null; then
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "No terminal available to confirm; aborting."
        exit 1
    fi
fi

echo "[1/4] Installing GPG key..."

# Download and install GPG public key.
# --yes: overwrite an existing keyring — without it a re-run of this installer
# fails (or hangs waiting for confirmation) because the file already exists.
if wget -qO - "${REPO_URL}/telarweb-archive-keyring.asc" | \
   gpg --dearmor --yes -o "${KEYRING_PATH}"; then
    echo "  ✓ GPG key installed to ${KEYRING_PATH}"
else
    echo "  ✗ Failed to download or install GPG key"
    echo ""
    echo "Please check:"
    echo "  1. Internet connection is working"
    echo "  2. Repository URL is correct: ${REPO_URL}"
    echo ""
    exit 1
fi

echo ""
echo "[2/4] Adding APT repository..."

# Add APT source
cat > "${SOURCES_FILE}" <<EOF
# TelarWeb APT Repository
# Raspberry Pi WiFi Provisioning via BLE
deb [signed-by=${KEYRING_PATH}] ${REPO_URL} trixie main
EOF

echo "  ✓ Repository added to ${SOURCES_FILE}"

echo ""
echo "[3/4] Updating package list..."

# Update APT cache
if apt-get update; then
    echo "  ✓ Package list updated"
else
    echo "  ✗ Failed to update package list"
    echo ""
    echo "Possible issues:"
    echo "  1. Repository is not accessible"
    echo "  2. GPG signature verification failed"
    echo ""
    echo "Try running: apt-get update"
    echo ""
    exit 1
fi

echo ""
echo "[4/4] Installing TelarWeb..."

# Install telarweb package
if apt-get install -y telarweb; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get IP address
    IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')

    if [ -n "$IP_ADDR" ]; then
        echo "  Web dashboard (after installing the companion): http://${IP_ADDR}:8088"
        echo "  or:                                             http://$(hostname).local:8088"
    else
        echo "  Web dashboard (after installing the companion): http://$(hostname).local:8088"
    fi

    echo ""
    echo "  BLE device: Pi-Setup"
    echo "  Use the TelarWeb Android app to configure WiFi"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Optional: Install Pi-hole companion"
    echo "  sudo apt install telarweb-pihole-companion"
    echo ""
    echo "To update in the future:"
    echo "  sudo apt update && sudo apt upgrade"
    echo ""
    echo "Factory reset:"
    echo "  sudo pi-factory-reset"
    echo ""
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Installation Failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please check the errors above and try again."
    echo ""
    echo "For help, visit:"
    echo "  https://github.com/flodek/telaweb-apt/issues"
    echo ""
    exit 1
fi
