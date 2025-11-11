#!/usr/bin/env bash
set -e # エラーが出たら即座に停止

# --- 設定 ---
HOST_FLAKE_NAME="nixos"
GIT_BRANCH="main"
# ---

echo "--- Applying NixOS System Updates ---"

echo '--- Pulling latest changes from Git ($GIT_BRANCH) ---'
git pull origin $GIT_BRANCH

echo '--- Updating flake inputs (like nixos-dev-base) ---'
sudo nix flake update

echo '---  Rebuild NixOS ---'
sudo nixos-rebuild switch --flake .#$HOST_FLAKE_NAME

echo '--- Update Complete ---'