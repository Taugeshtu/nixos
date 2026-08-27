{ pkgs, ... }:

{
  home.username = "tau";
  home.homeDirectory = "/home/tau";
  home.stateVersion = "25.05";

  # Universal user packages (CLI, hardware, audio/network GUIs)
  home.packages = with pkgs; [
    # Fonts
    comfortaa
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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tykhon \"Taugeshtu\" Gusiev";
        email = "tau.tihon@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.micro = {
    enable = true;
    settings = {
      mkparents = true;
      diffgutter = true;
      parsecursor = true;
      scrollbar = true;
    };
  };

  xdg.configFile."micro/bindings.json".text = builtins.toJSON {
    "Alt-/" = "lua:comment.comment";
    "CtrlUnderscore" = "lua:comment.comment";
  };

  programs.home-manager.enable = true;
}
