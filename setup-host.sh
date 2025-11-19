#!/usr/bin/env bash
set -e

# --- 設定 ---
CONFIG_DIR_TARGET="/home/dev/src/nixos-host-config"
CONFIG_DIR_SYMLINK="/etc/nixos"
HOST_FLAKE_NAME="nixos"
CONFIG_SOURCE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GITHUB_USER="$1"
# ---

echo "--- NixOS First-Time Setup (Impure Mode) ---"
echo "Running from: $CONFIG_SOURCE_DIR"

# 1. 既にセットアップ済みか確認
if [ -L "$CONFIG_DIR_SYMLINK" ] && [ "$(readlink -f "$CONFIG_DIR_SYMLINK")" = "$CONFIG_DIR_TARGET" ]; then
  echo "Setup already complete."
  exit 0
fi

# 2. 既存の /etc/nixos をバックアップ
if [ -d "$CONFIG_DIR_SYMLINK" ] && [ ! -L "$CONFIG_DIR_SYMLINK" ]; then
  echo "Backing up existing /etc/nixos..."
  mv "$CONFIG_DIR_SYMLINK" /etc/nixos.bak
elif [ -L "$CONFIG_DIR_SYMLINK" ]; then
  rm "$CONFIG_DIR_SYMLINK"
fi

# 3. ハードウェア設定の確保
echo "Ensuring hardware-configuration.nix exists..."
if [ ! -f "$CONFIG_SOURCE_DIR/hardware-configuration.nix" ]; then
    if [ -f /etc/nixos.bak/hardware-configuration.nix ]; then
        cp /etc/nixos.bak/hardware-configuration.nix "$CONFIG_SOURCE_DIR/"
    else
        echo "ERROR: hardware-configuration.nix not found!"
        exit 1
    fi
fi

# 4. 設定移動とリンク作成 (ビルド前にやってしまう)
# Impureモードで /etc/nixos/... を参照させるため、先にリンクが必要
echo "Moving config to $CONFIG_DIR_TARGET..."
mkdir -p "$(dirname "$CONFIG_DIR_TARGET")"
# 自分自身の中に移動しようとしないかチェック
if [ "$CONFIG_SOURCE_DIR" != "$CONFIG_DIR_TARGET" ]; then
    mv "$CONFIG_SOURCE_DIR" "$CONFIG_DIR_TARGET"
fi

echo "Creating symlink: $CONFIG_DIR_SYMLINK -> $CONFIG_DIR_TARGET"
ln -s "$CONFIG_DIR_TARGET" "$CONFIG_DIR_SYMLINK"
chown -R dev:users "$(dirname "$CONFIG_DIR_TARGET")"

# 5. 最初のビルド (Impure)
echo "Running first build..."
nixos-rebuild switch --flake "$CONFIG_DIR_TARGET#$HOST_FLAKE_NAME" --impure

# ==========================================
# SSH Key Injection
# ==========================================
echo "--- Configuring SSH keys for 'dev' user ---"
SSH_DIR="/home/dev/.ssh"
AUTH_KEYS_FILE="$SSH_DIR/authorized_keys"
SSH_KEYS_CONTENT=""

if [ -n "$GITHUB_USER" ]; then
    echo "Fetching keys from GitHub for user '$GITHUB_USER'..."
    SSH_KEYS_CONTENT=$(curl -fsSL "https://github.com/${GITHUB_USER}.keys" || echo "")
elif [ ! -t 0 ]; then
    echo "Reading keys from stdin..."
    SSH_KEYS_CONTENT=$(cat)
else
    echo "Skipping SSH key configuration."
fi

if [ -n "$SSH_KEYS_CONTENT" ]; then
    mkdir -p "$SSH_DIR"
    echo "$SSH_KEYS_CONTENT" > "$AUTH_KEYS_FILE"
    chmod 700 "$SSH_DIR"
    chmod 600 "$AUTH_KEYS_FILE"
    chown -R dev:users "$SSH_DIR"
    echo "SSH keys configured."
fi
# ==========================================

echo "--- Provisioning Complete! ---"