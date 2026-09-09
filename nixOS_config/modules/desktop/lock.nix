# Lock screen, idle daemon, and lock-screen coercion scripts
{ pkgs, ... }:

{
  security.pam.services.gtklock = {};
  security.pam.services.strikeface = {};

  home-manager.users.tau = { ... }: {
    # Lock & idle configuration
    xdg.configFile."gtklock".source = ./niri/config/gtklock;
    xdg.configFile."swayidle".source = ./niri/config/swayidle;
    xdg.configFile."niri/lock.kdl".source = ./niri/config/snippets/lock.kdl;

    # Lock helper scripts
    home.file.".local/bin/img-coercer" = { source = ./niri/bin/img-coercer; executable = true; };
    home.file.".local/bin/chastity" = { source = ./niri/bin/chastity; executable = true; };
    home.file.".local/bin/chastity-img" = { source = ./niri/bin/chastity-img; executable = true; };
    home.file.".local/bin/try-chastity-img" = { source = ./niri/bin/try-chastity-img; executable = true; };

    home.packages = with pkgs; [
      gtklock
      swayidle
    ];
  };
}
