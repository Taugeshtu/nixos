{ pkgs, ... }:

{
  # Tailscale client daemon
  services.tailscale = {
    enable = true;
    openFirewall = true; # Opens UDP 41641 for direct P2P WireGuard
    useRoutingFeatures = "client";
  };

  # Firewall rules for Tailscale overlay (restricted ports only)
  networking.firewall = {
    checkReversePath = "loose"; # Prevents asymmetric routing packet drops
    interfaces."tailscale0" = {
      allowedTCPPorts = [
        22    # SSH & SFTP (Thunar)
        3000  # Brog web UI
      ];
      allowedTCPPortRanges = [
        { from = 8080; to = 8085; }   # Model serving (llama, ninfer, minicpm)
        { from = 47984; to = 48010; } # Sunshine / Moonlight streaming
      ];
      allowedUDPPortRanges = [
        { from = 47998; to = 48010; } # Sunshine / Moonlight streaming
      ];
    };
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
