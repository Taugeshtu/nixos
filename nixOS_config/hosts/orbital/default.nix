{ config, pkgs, lib, inputs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ../../modules/core/base.nix
  ];

  networking.hostName = "orbital";

  # --- Static Networking (Contabo Cloud VPS) ---
  networking.networkmanager.enable = lib.mkForce false;
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0 = {
    ipv4.addresses = [
      {
        address = "13.140.157.81";
        prefixLength = 18;
      }
    ];
    ipv6.addresses = [
      {
        address = "2a02:c207:2367:738::1";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway = {
    address = "13.140.128.1";
    interface = "eth0";
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" ];

  # --- Bootloader for BIOS boot on GPT ---
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  system.stateVersion = "25.05";

  # --- Firewall ---
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 3478 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # --- OpenSSH Daemon ---
  services.openssh = {
    enable = true;
    openFirewall = true; # Open port 22 on WAN
    settings = {
      PermitRootLogin = "prohibit-password"; # Key-only root for bootstrap and recovery
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # --- Users & Access ---
  security.sudo.wheelNeedsPassword = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0YP/FMOt54WpTqdtX3tPGH5mqLUIZ1lELICQEpf57M tau@codex"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3gJE12NzJzJ/asmixzkL0MqVbeJ5+To1SpOUgownO7 tau@tower"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEQ7fhPpYcsefn3G/ohpEzQH9Vg+nepD8nB6g4i3uBZ tau@slate"
  ];

  users.users.tau = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "podman" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0YP/FMOt54WpTqdtX3tPGH5mqLUIZ1lELICQEpf57M tau@codex"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3gJE12NzJzJ/asmixzkL0MqVbeJ5+To1SpOUgownO7 tau@tower"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEQ7fhPpYcsefn3G/ohpEzQH9Vg+nepD8nB6g4i3uBZ tau@slate"
    ];
  };

  # --- Container Runtime (Podman) ---
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  # Allow non-root podman containers to bind directly to ports 80 and 443
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # --- Native Caddy Reverse Proxy ---
  services.caddy = {
    enable = true;
    virtualHosts = {
      "tau.games" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
      "www.tau.games" = {
        extraConfig = ''
          redir https://tau.games{uri} permanent
        '';
      };
      "orbital.tau.games" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8085 {
            flush_interval -1
          }
        '';
      };
    };
  };

  # --- Native Headscale Control Plane ---
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8085;
    settings = {
      server_url = "https://orbital.tau.games";
      dns = {
        magic_dns = true;
        base_domain = "mesh.internal";
        nameservers.global = [ "1.1.1.1" "1.0.0.1" ];
      };
      derp.server = {
        enabled = true;
        region_id = 999;
        region_code = "orbital";
        region_name = "Orbital Embedded DERP";
        stun_listen_addr = "0.0.0.0:3478";
      };
    };
  };

  # --- Tailscale Node Daemon ---
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # --- Server Memory & Hygiene ---
  services.qemuGuest.enable = true;
  zramSwap.enable = true;
  boot.tmp.cleanOnBoot = true;
}
