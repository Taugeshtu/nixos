{ pkgs, ... }:

{
  home.username = "tau";
  home.homeDirectory = "/home/tau";
  home.stateVersion = "25.05";

  # Universal user packages (CLI, hardware, audio/network GUIs)
  home.packages = with pkgs; [
    # Fonts
    mononoki
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji

    # Hardware diagnostics & control
    nvtopPackages.full
    brightnessctl
    pciutils
    usbutils
    mesa-demos
    vulkan-tools
    wireplumber
    pulseaudio

    # Desktop control GUIs
    pavucontrol
    networkmanagerapplet
    blueman

    # Shell utilities
    bat
    eza
    ripgrep
    fd
    jq
    macchina
    which
  ];

  programs.home-manager.enable = true;
}
