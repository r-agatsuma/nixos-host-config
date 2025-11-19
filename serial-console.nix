{ config, lib, pkgs, ... }:
let
    # 管理用のシリアルポートを定義
    serialTty = "ttyS0";
    serialTtyNum = "0";
    # ユーザ名を定義
    failsafeUser = "consoleadmin";
in
{
    # -----------------------------------------------------------------
    # 1. シリアルコンソールを有効化
    # -----------------------------------------------------------------
    # シリアルコンソールの設定
    boot.kernelParams = [ "console=${serialTty},115200n8" ];
    # grubもシリアルコンソールに表示させる設定
    boot.loader.grub.extraConfig = ''
        serial --unit=${serialTtyNum} --speed=115200 --word=8 --parity=no --stop=1
        terminal_input serial
        terminal_output serial
    '';
    # systemd にシリアルポートでログインプロンプト(getty)を起動させる（明示的）
    systemd.services."serial-getty@${serialTty}" = {
        enable = true;
        description = "Serial Console Login";
        serviceConfig = {
            ExecStart = "-/run/current-system/sw/bin/agetty -L ${serialTty} 115200 vt100";
            Restart = "always";
            RestartSec = 10;
            StandardInput = "tty";
            StandardOutput = "tty";
        };
    };

    # -----------------------------------------------------------------
    # 2. ユーザー定義
    # -----------------------------------------------------------------
    users.users.${failsafeUser} = {
        isNormalUser = true;
        description = "Failsafe Serial Console Administrator";
        extraGroups = [ "wheel" ]; # wheelグループに追加
        # 重要：パスワードを設定する
        # sudo mkdir -p /etc/nixos/secrets
        # sudo sh -c 'mkpasswd -m sha-512 > /etc/nixos/secrets/console-password'
        # sudo chmod 600 /etc/nixos/secrets/console-password
        hashedPasswordFile = "/etc/nixos/secrets/console-password";
    };

    # -----------------------------------------------------------------
    # 3. このユーザーのログインを「シリアル」のみに制限
    # -----------------------------------------------------------------
    environment.etc."security/access.conf".text = ''
    # ルール1:
    # 許可する: ${failsafeUser} は、ローカルTTY(tty1-6)とシリアル(${serialTty}) から "のみ"
    +:${failsafeUser}:tty1 tty2 tty3 tty4 tty5 tty6 ${serialTty}
    
    # ルール2 (else if):
    # 拒否する: ${failsafeUser} は、それ以外(ALL) からは "ダメ"
    -:${failsafeUser}:ALL
    
    # ルール3 (else):
    # 許可する: それ以外の(ALL)ユーザーは、どこからでも(ALL)
    +:ALL:ALL
  '';

  # -----------------------------------------------------------------
  # (B) このルール(pam_access.so)を "login" と "sshd" に適用
  # -----------------------------------------------------------------
  security.pam.services.login.rules.account.access-control = {
    enable = true;
    modulePath = "${config.security.pam.package}/lib/security/pam_access.so";
    control = "required";
    order = config.security.pam.services.login.rules.account.unix.order - 10;
  };

  security.pam.services.sshd.rules.account.access-control = {
    enable = true;
    modulePath = "${config.security.pam.package}/lib/security/pam_access.so";
    control = "required";
    order = config.security.pam.services.sshd.rules.account.unix.order - 10;
  };
}