#!/usr/bin/env bash
set -e # エラーが出たら即座に停止

# --- 設定 ---
CONFIG_DIR_TARGET="/home/dev/src/nixos-host-config" # 設定ファイルの最終的な場所
CONFIG_DIR_SYMLINK="/etc/nixos"                  # NixOSが参照するシンボリックリンク
HOST_FLAKE_NAME="nixos"                          # flake.nixで定義したホスト名
# このスクリプトが今いるディレクトリ
CONFIG_SOURCE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# ---

echo "--- NixOS First-Time Setup ---"
echo "Running from: $CONFIG_SOURCE_DIR"

# 1. 既にセットアップ済みか確認
if [ -L "$CONFIG_DIR_SYMLINK" ] && [ "$(readlink -f "$CONFIG_DIR_SYMLINK")" = "$CONFIG_DIR_TARGET" ]; then
  echo "Setup already complete (symlink $CONFIG_DIR_SYMLINK -> $CONFIG_DIR_TARGET exists)."
  echo "Log in as 'dev' user to manage this system."
  exit 0
fi

# 2. 既存の /etc/nixos をバックアップ
if [ -d "$CONFIG_DIR_SYMLINK" ] && [ ! -L "$CONFIG_DIR_SYMLINK" ]; then
  echo "Backing up existing /etc/nixos to /etc/nixos.bak..."
  mv "$CONFIG_DIR_SYMLINK" /etc/nixos.bak
elif [ -L "$CONFIG_DIR_SYMLINK" ]; then
  echo "Removing broken symlink $CONFIG_DIR_SYMLINK..."
  rm "$CONFIG_DIR_SYMLINK"
fi

# 3. マシン固有の hardware-configuration.nix をバックアップからコピー
echo "Copying hardware-configuration.nix from /etc/nixos.bak..."
if [ ! -f /etc/nixos.bak/hardware-configuration.nix ]; then
    echo "ERROR: /etc/nixos.bak/hardware-configuration.nix not found!"
    echo "This file is required. Please ensure you ran nixos-generate-config first."
    exit 1
fi
cp /etc/nixos.bak/hardware-configuration.nix "$CONFIG_SOURCE_DIR/"
echo "-> hardware-configuration.nix copied."

# 4. 最初のビルド
echo "Running first build from $CONFIG_SOURCE_DIR..."
echo "This will create the 'dev' user and their home directory..."
nixos-rebuild switch --flake "$CONFIG_SOURCE_DIR#$HOST_FLAKE_NAME"

# 5. ビルド成功。設定ファイルを最終的な場所 (/home/dev/...) に移動
echo "Build successful. Moving config to $CONFIG_DIR_TARGET..."
mkdir -p "$(dirname "$CONFIG_DIR_TARGET")"
mv "$CONFIG_SOURCE_DIR" "$CONFIG_DIR_TARGET"

# 6. dev ユーザーに所有権を渡す
chown -R dev:users "$(dirname "$CONFIG_DIR_TARGET")"

# 7. 最終的なシンボリックリンクを作成
echo "Creating final symlink: $CONFIG_DIR_SYMLINK -> $CONFIG_DIR_TARGET"
ln -s "$CONFIG_DIR_TARGET" "$CONFIG_DIR_SYMLINK"

echo "---"
echo "--- Provisioning Complete! ---"
echo "Log out of 'root' and log in as the 'dev' user."
echo "As 'dev', initialize Git and authenticate with 'gh auth login'."