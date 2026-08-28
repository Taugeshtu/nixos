{ pkgs, ... }:

{
  # Tailscale client daemon
  services.tailscale = {
    enable = true;
    openFirewall = true; # Opens UDP 41641 for direct P2P WireGuard
    useRoutingFeatures = "client";
  };

  # Firewall rules for Tailscale overlay
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose"; # Prevents asymmetric routing packet drops
  };

  # OpenSSH server (accessible only via trustedInterfaces: tailscale0)
  services.openssh = {
    enable = true;
    openFirewall = false; # Keep port 22 closed on WAN/WiFi interfaces
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
}
