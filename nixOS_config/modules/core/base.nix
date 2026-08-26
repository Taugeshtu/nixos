# Shared base — imported by every machine
{ pkgs, ... }:

{
  # --- Nix ---
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- Locale ---
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_NUMERIC   = "uk_UA.UTF-8";
    LC_TIME      = "uk_UA.UTF-8";
    LC_MONETARY  = "uk_UA.UTF-8";
    LC_PAPER     = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_COLLATE   = "C";
  };

  # --- TTY console ---
  # TODO: wire in custom PSF font (mononoki) once we have it packaged
  console.keyMap = "ua-utf";
  console.colors = [
    "f9f9f9" "ff004f" "05996b" "bd852b" "f53c3c" "b000b0" "2f7791" "000000"
    "3d3d3d" "f53c3c" "00FFB0" "ffb37b" "7f052c" "b874b8" "49a1b3" "f83875"
  ];

  # --- DNS ---
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = "1.1.1.1 8.8.8.8";
      FallbackDNS = "1.0.0.1 8.8.4.4";
      DNSSEC = "false";
    };
  };

  # --- Memory & Swap ---
  services.earlyoom.enable = true;

  # --- Networking ---
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  # --- User Path ---
  environment.localBinInPath = true;

  # --- Base packages ---
  environment.systemPackages = with pkgs; [
    micro git htop tmux
    ripgrep bat fd wget curl
    pciutils usbutils lshw
    file unzip zip nodejs tree
    (python3.withPackages (ps: with ps; [ pillow numpy ]))
    glib
    rustc cargo pkg-config gcc
    alacritty
    android-tools
    sops age ssh-to-age
    mergerfs
    mutagen uv chafa veracrypt
  ];
  environment.variables.EDITOR = "micro";

  programs.fuse.userAllowOther = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    glib
    gtk4
    gtksourceview5
    pango
    cairo
    gdk-pixbuf
    graphene
  ];
}
