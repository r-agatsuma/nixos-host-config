{ config, lib, pkgs, ... }:
{
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    neovim
    tmux
    git
    gh
    google-cloud-sdk
    gemini-cli
    dive
    podman-tui
    docker-compose
    direnv
  ];

  # Enavle vim and vi alias
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Enable tailscale 
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Enable nix ld
  programs.nix-ld.enable = true;
  # Enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Enable firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

  # Enable flake and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}