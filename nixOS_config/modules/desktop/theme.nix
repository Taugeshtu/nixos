# Desktop Theming (Fonts, Cursors, Theme integration)
{ pkgs, ... }:

let
  redOmenCursorPkg = pkgs.runCommand "redomen-cursor" {} ''
    mkdir -p $out/share/icons/RedOmen
    cp -r ${./niri/config/icons/RedOmen}/* $out/share/icons/RedOmen/
  '';
in
{
  home-manager.users.tau = { ... }: {
    # Fontconfig rendering parameters
    xdg.configFile."fontconfig/fonts.conf".source = ./niri/config/fontconfig/fonts.conf;

    # Cursor theme
    home.pointerCursor = {
      enable = true;
      name = "RedOmen";
      size = 24;
      package = redOmenCursorPkg;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
