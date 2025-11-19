{ config, lib, pkgs, ... }:
{
    # GUI (Hyperland)
    environment.systemPackages = with pkgs; [
        kitty 
    ];
    services.xserver.enable = true;
    programs.hyprland.enable = true;
    programs.dconf.enable = true;
    xdg.portal.enable = true;
    security.pam.services.swaylock.text = "auth include login";

    # インプットメソッド
    i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = [pkgs.fcitx5-mozc];
    };
    # フォント
    fonts = {
        packages = with pkgs; [
            noto-fonts-cjk-serif
            noto-fonts-cjk-sans
            noto-fonts-emoji
            nerd-fonts.jetbrains-mono
            nerd-fonts.fira-code
        ];
        fontDir.enable = true;
        fontconfig = {
            defaultFonts = {
            serif = ["Noto Serif CJK JP" "Noto Color Emoji"];
            sansSerif = ["Noto Sans CJK JP" "Noto Color Emoji"];
            monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
            emoji = ["Noto Color Emoji"];
            };
        };
    };
    # オーディオ
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        jack.enable = true;
        pulse.enable = true;
    };

    # -----------------------------------------------------------------
    # ユーザー設定
    # -----------------------------------------------------------------
    # (1) `dev` ユーザーの「パスワード」を定義
    # (GUIログインに必須)
    # このハッシュは 'mkpasswd -m sha-512' コマンドで生成
    # "YOUR_PASSWORD" は平文で書くな！
    # users.users.dev.hashedPassword = "!!PASTE_YOUR_DEV_USER_HASH_HERE!!";
    # (2) パスワードの強制有効化
    # security.sudo.wheelNeedsPassword = lib.mkForce true;
}
