{
  description = "Host Configuration";

  inputs = {
    # どのブランチを参照するか指定
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          networking.hostName = "nixos"; # ホスト名
          system.stateVersion = "25.05"; # どの安定版リリースのデフォルト値や動作を前提に書かれたものか指定，変更するな
        }
        ./hardware-configuration.nix  # マシン固有の設定
        ./dev-base.nix                # 共通パッケージ
        ./user.nix                    # dev ユーザー SSHキーの設定など           
        ./boot-bios.nix               # biosによる起動
        # ./boot-uefi.nix             # uefiによる起動(オプション)
        ./serial-console.nix          # シリアルコンソールの有効化(オプション)
        ./qemu-guest.nix              # ゲストエージェントの有効化(オプション)
        # ./gui.nix                   # GUIの有効化(オプション)
      ];
    };

    nixosConfigurations."ci-test" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-ci.nix
        ./dev-base.nix 
        ./user.nix
        ./ci-test.nix
        ./gui.nix
      ];
    };
  };
}