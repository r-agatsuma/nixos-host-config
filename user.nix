{ config, lib, pkgs, ... }:
{
  # ユーザー設定
  users.users.dev = {
    isNormalUser = true;
    description = "Developer User";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # ADD YOUR SSH PUBLIC KEYS HERE
      # "ssh-ed25519 AAAA... USER1@KEY1"
      # "ssh-ed25519 AAAA... USER2@KEY2"
    ];
  };

  # ルートログインの無効化
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";

  # wheel グループのパスワードなし sudo
  security.sudo.wheelNeedsPassword = false;

  # 地域/言語設定
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.supportedLocales = [ "ja_JP.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  console.keyMap = "jp106";
}