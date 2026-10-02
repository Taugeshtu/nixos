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

    # Ensure document portal recovers if FUSE unmounts or crashes
    systemd.user.services.xdg-document-portal = {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "1s";
      };
    };

    # Reconnect document portal on rebuild switch to prevent zombie detached FUSE mounts
    system.activationScripts.restartXdgDocumentPortal = {
      supportsDryActivation = true;
      text = ''
        for uid_dir in /run/user/*; do
          if [ -d "$uid_dir" ] && [ -S "$uid_dir/systemd/private" ]; then
            uid=$(basename "$uid_dir")
            ${pkgs.systemd}/bin/systemctl --machine="$uid@.host" --user restart xdg-document-portal.service 2>/dev/null || true
          fi
        done
      '';
    };
  };
}
