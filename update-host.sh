#!/usr/bin/env bash
set -e

# --- 設定 ---
HOST_FLAKE_NAME="nixos"
GIT_BRANCH="main"
# ---

echo "--- Applying NixOS System Updates (Impure) ---"

echo "--- Pulling latest changes from Git ($GIT_BRANCH) ---"
git pull origin $GIT_BRANCH

echo '--- Updating flake inputs ---'
sudo nix flake update

echo '--- Rebuild NixOS ---'
sudo nixos-rebuild switch --flake .#$HOST_FLAKE_NAME --impure

echo '--- Update Complete ---'