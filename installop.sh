#!/bin/bash
# =============================================================================
# Optia Kiosk - Installer
# Run this on a fresh Raspberry Pi after GParted partition setup
#
# Usage (paste into SSH):
#   curl -s https://raw.githubusercontent.com/Forge-Vision/optiwaste_firmware/main/install.sh | sudo bash
# =============================================================================

set -e

REPO="Forge-Vision/optiwaste_firmware"
OPTIA_DIR="/data/optia"

echo ""
echo "============================================"
echo " Optia Kiosk Installer"
echo "============================================"
echo ""

# Must be root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo"
    exit 1
fi

# Ask for token interactively — hidden like a password
echo "Enter your GitHub Personal Access Token:"
read -r TOKEN
echo ""

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: Token cannot be empty"
    exit 1
fi

# Verify token works before proceeding
echo "Verifying token..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$REPO")

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "ERROR: Token invalid or no access to repo (HTTP $HTTP_CODE)"
    exit 1
fi
echo "Token verified OK"
echo ""

# =============================================================================
# 1. Download and run partition.py
# =============================================================================
echo "[1/3] Setting up /data partition..."

curl -s -H "Authorization: token $TOKEN" \
    "https://raw.githubusercontent.com/$REPO/main/partition.py" \
    -o /tmp/partition.py

sudo -u pi python3 /tmp/partition.py
rm /tmp/partition.py

echo ""

# =============================================================================
# 2. Clone repo into /data/optia
# =============================================================================
echo "[2/3] Cloning firmware..."

mkdir -p "$OPTIA_DIR"
chown pi:pi "$OPTIA_DIR"

sudo -u pi git clone "https://$TOKEN@github.com/$REPO.git" "$OPTIA_DIR"

# Clear token from git remote URL immediately after clone
cd "$OPTIA_DIR"
git remote set-url origin "https://github.com/$REPO.git"

echo ""

# =============================================================================
# 3. Run master setup
# =============================================================================
echo "[3/3] Running master setup..."
echo ""

bash "$OPTIA_DIR/master_setup.sh"

# master_setup.sh reboots automatically
