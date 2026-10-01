# Productivity & Future desktop extension (to-day, purse, edge-glide, lsp-broker, current)
{ config, lib, pkgs, inputs, ... }:

let
  todayPkg = pkgs.rustPlatform.buildRustPackage {
    pname = "to-day";
    version = "0.6.0";
    src = inputs.to-day;
    cargoLock.lockFile = "${inputs.to-day}/Cargo.lock";

    dontStrip = true;

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.wrapGAppsHook4
    ];
    buildInputs = [
      pkgs.gtk4
      pkgs.gtk4-layer-shell
      pkgs.glib
    ];

    postInstall = ''
      echo "=== TO-DAY BUILD: Running self-patcher in postInstall ==="
      $out/bin/to-day --set-log-dir "/home/tau/00_INGRESS"
      echo "=== TO-DAY BUILD: Finished self-patcher in postInstall ==="
    '';

    postFixup = ''
      echo "=== TO-DAY BUILD: Post-fixup files ==="
      ls -la $out/bin/
    '';
  };

  currentPkg = inputs.current.packages.${pkgs.system}.default;
in
{
  nixpkgs.overlays = [
    (final: prev: let
      wrapThunar = base: (prev.symlinkJoin {
        name = "thunar-wrapped-current-${base.version}";
        paths = [ base ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/thunar" \
            --prefix LD_PRELOAD : "${currentPkg}/lib/libthunar-current.so"

          rm -rf "$out/lib/systemd/user"
          mkdir -p "$out/lib/systemd/user"

          for file in "lib/systemd/user/thunar.service" \
            "share/dbus-1/services/org.xfce.FileManager.service" \
            "share/dbus-1/services/org.xfce.Thunar.FileManager1.service" \
            "share/dbus-1/services/org.xfce.Thunar.service"
          do
            if [ -f "${base}/$file" ]; then
              rm -f "$out/$file"
              mkdir -p "$(dirname "$out/$file")"
              substitute "${base}/$file" "$out/$file" \
                --replace-warn "${base}" "$out"
            fi
          done
        '';
      }) // (prev.lib.optionalAttrs (base ? dev) { inherit (base) dev; });
      wrapped = wrapThunar prev.thunar;
    in {
      thunar = wrapped // {
        override = args: wrapThunar (prev.thunar.override args);
      };
    })
  ];

  home-manager.users.tau = { ... }: {
    # Future dotfiles & configs
    xdg.configFile."purse".source = ./niri/config/purse;
    xdg.configFile."lsp-broker".source = ./niri/config/lsp-broker;
    xdg.configFile."lite-xl" = {
      source = ./niri/config/lite-xl;
      recursive = true;
    };
    xdg.configFile."touch-edge-glide".source = ./niri/config/touch-edge-glide;
    xdg.configFile."libinput-gestures.conf".source = ./niri/config/libinput-gestures.conf;
    xdg.configFile."niri/future.kdl".source = ./niri/config/snippets/future.kdl;
    xdg.configFile."Thunar/uca.xml".source = ./niri/config/Thunar/uca_full.xml;

    # Future helper scripts
    home.file.".local/bin/touch-edge-glide" = { source = ./niri/bin/touch-edge-glide; executable = true; };
    home.file.".local/bin/smart-today" = { source = ./niri/bin/smart-today; executable = true; };
    home.file.".local/bin/current-today" = { source = ./niri/bin/current-today; executable = true; };
    home.file.".local/bin/current-grass" = { source = ./niri/bin/current-grass; executable = true; };
    home.file.".local/bin/prj" = { source = ./niri/bin/prj; executable = true; };
    home.file.".local/bin/purse-defs-smart" = { source = ./niri/bin/purse-defs-smart; executable = true; };
    home.file.".local/bin/purse-refs-smart" = { source = ./niri/bin/purse-refs-smart; executable = true; };
    home.file.".local/bin/purse-defs.sh" = { source = ./niri/bin/purse-defs.sh; executable = true; };
    home.file.".local/bin/purse-refs.sh" = { source = ./niri/bin/purse-refs.sh; executable = true; };
    home.file.".local/bin/into-purse.sh" = { source = ./niri/bin/into-purse.sh; executable = true; };
    home.file.".local/bin/strip_to_audio" = { source = ./niri/bin/strip_to_audio; executable = true; };
    home.file.".local/bin/adb_pull_camera" = { source = ./niri/bin/adb_pull_camera; executable = true; };
    home.file.".local/bin/deduplicate" = { source = ./niri/bin/deduplicate; executable = true; };
    home.file.".local/bin/to-ingress" = { source = ./niri/bin/to-ingress; executable = true; };

    # Desktop entries
    xdg.desktopEntries.purse-niri = {
      name = "Purse";
      exec = "into-purse.sh %F";
      noDisplay = true;
      terminal = false;
      mimeType = [
        "text/plain" "text/markdown" "image/png" "image/jpeg"
        "image/gif" "image/svg+xml" "image/webp" "image/bmp"
        "image/x-bmp" "image/tiff" "model/stl" "application/sla"
        "model/x.stl-ascii" "model/x.stl-binary"
      ];
    };

    # Systemd user services
    systemd.user.services.touch-edge-glide = {
      Unit = {
        Description = "TouchEdgeGlide daemon";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.local/bin/touch-edge-glide";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.services.lsp-broker = {
      Unit = {
        Description = "LSP-servers broker-manager";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.local/bin/lsp-broker --daemon";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.services.current = {
      Unit = {
        Description = "Current Context Daemon";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${currentPkg}/bin/current --daemon";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Packages
    home.packages = with pkgs; [
      todayPkg
      currentPkg
      libinput-gestures
      ydotool
      wtype
      xdotool

      # Future LSP servers
      rust-analyzer
      markdown-oxide

      # GTK4 development libraries (for Purse and local tools)
      gtk4
      gtk4-layer-shell
      gtksourceview5
    ];
  };
}
