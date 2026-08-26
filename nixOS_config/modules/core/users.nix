# User definitions — kiosk and tau
# Passwords: set manually after first boot via passwd.
# For Pathfinder MVP, initialPassword is a placeholder — change immediately.
{ ... }:

{
  users.mutableUsers = true;

  users.users.tau = {
    isNormalUser = true;
    uid = 1000;
    description = "tau";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"  # nm management
      "video"           # backlight, wluma
      "input"           # keyd
      "uinput"          # TouchEdgeGlide virtual mouse
      "audio"           # sound
      "ydotool"         # ydotool daemon socket access
    ];
    initialPassword = "nixos";
  };

  # Kiosk user: unprivileged, no sudo, lives on unencrypted system LV
  users.users.kiosk = {
    isNormalUser = true;
    uid = 1001;
    home = "/home/kiosk";
    createHome = true;
    description = "Kiosk Environment";
    extraGroups = [
      "video"
      "input"
      "networkmanager"
      "audio"
    ];
    initialPassword = "kiosk";
  };
}
