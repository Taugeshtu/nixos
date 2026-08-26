# Flatpak base infrastructure & management tools
{ config, pkgs, lib, ... }:

{
  options.services.flatpak.packages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "List of Flatpak application IDs to install from Flathub.";
  };

  config = {
    services.flatpak.enable = true;

    # Core Flatpak management tools
    services.flatpak.packages = [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
    ];

    # Ensure Flathub repository is registered system-wide
    systemd.services.flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };

    # Auto-install declared Flatpaks when network is up
    systemd.user.services.flatpak-managed = {
      description = "Declarative Flatpaks Auto-Installer";
      after = [ "network-online.target" "flatpak-repo.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "install-flatpaks" ''
          ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          ${lib.concatMapStringsSep "\n" (app: "${pkgs.flatpak}/bin/flatpak install -y --user --noninteractive flathub ${app} || true") config.services.flatpak.packages}
        ''}";
        RemainAfterExit = true;
      };
    };
  };
}
