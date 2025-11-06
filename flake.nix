{
  description = "Host Configuration";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-25.05";

    nix-dev-base = {
      url = "github:r-agatsuma/nix-dev-base";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-dev-base, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./hardware-configuration.nix
        nix-dev-base.nixosModules.default
        ./user.nix
        { 
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          networking.hostName = "nixos";
          system.stateVersion = "25.05";
        }
      ];
    };

    nixosConfigurations."ci-test" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-ci.nix
        nix-dev-base.nixosModules.default
        ./user.nix
        { 
          users.allowNoPasswordLogin = true;
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          networking.hostName = "nixos";
          system.stateVersion = "25.05";
        }
      ];
    };
  };
}