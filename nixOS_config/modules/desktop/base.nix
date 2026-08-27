# Base Desktop Environment (Niri, Greetd, Foot, Waybar, Thunar, Media tools)
{ config, lib, pkgs, inputs, ... }:

let
  btGhostNotePkg = pkgs.rustPlatform.buildRustPackage {
    pname = "bt_ghost_note";
    version = "0.1.0";
    src = inputs.bt-ghost-note;
    cargoLock.lockFile = "${inputs.bt-ghost-note}/Cargo.lock";

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.wrapGAppsHook3
    ];
    buildInputs = [
      pkgs.gtk3
      pkgs.glib
      pkgs.libappindicator-gtk3
      pkgs.libayatana-appindicator
    ];

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${lib.makeBinPath [ pkgs.sox pkgs.procps pkgs.glib ]}
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libayatana-appindicator pkgs.libappindicator-gtk3 ]}
      )
    '';

    postInstall = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps
      cp icon.svg $out/share/icons/hicolor/scalable/apps/bt_ghost_note.svg
      cat <<EOF > $out/share/applications/bt_ghost_note.desktop
[Desktop Entry]
Type=Application
Name=BT Ghost Note
Comment=Keep Bluetooth active with white noise
Exec=$out/bin/bt_ghost_note
Icon=bt_ghost_note
Terminal=false
Categories=Utility;Audio;
EOF
    '';
  };
in
{
  # --- System Desktop Integration ---
  programs.niri.enable = true;
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xwayland
  ];
  programs.ydotool.enable = true;
  programs.dconf.enable = true;
  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  services.tumbler.enable = true;
  services.gvfs.enable = true; # for trash, mount handling in thunar

  # --- Login Greeter ---
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --remember --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
    };
  };

  # --- User Desktop Environment (tau) ---
  home-manager.users.tau = { ... }: {
    # Pure in-store managed dotfiles
    xdg.configFile."niri/lock.kdl".text = lib.mkDefault "";
    xdg.configFile."niri/future.kdl".text = lib.mkDefault "";
    xdg.configFile."niri".source = ./niri/config/niri;
    xdg.configFile."foot".source = ./niri/config/foot;
    xdg.configFile."waybar".source = ./niri/config/waybar;
    xdg.configFile."mpv".source = ./niri/config/mpv;
    xdg.configFile."imv/config".source = ./niri/config/imv/config;
    xdg.configFile."macchina".source = ./niri/config/macchina;
    xdg.configFile."alacritty".source = ./niri/config/alacritty;
    xdg.configFile."htop/htoprc".source = ./niri/config/htop/htoprc;
    xdg.configFile."mimeapps.list".source = ./niri/config/mimeapps.list;
    xdg.configFile."Thunar/uca.xml".source = lib.mkDefault ./niri/config/Thunar/uca_base.xml;
    xdg.configFile."Thunar/accels.scm".source = ./niri/config/Thunar/accels.scm;

    # Core helper scripts
    home.file.".local/bin/niri-launcher" = { source = ./niri/bin/niri-launcher; executable = true; };
    home.file.".local/bin/smart-terminal" = { source = ./niri/bin/smart-terminal; executable = true; };
    home.file.".local/bin/niri-navigate" = { source = ./niri/bin/niri-navigate; executable = true; };
    home.file.".local/bin/niri-zen" = { source = ./niri/bin/niri-zen; executable = true; };
    home.file.".local/bin/foot-on-path" = { source = ./niri/bin/foot-on-path; executable = true; };
    home.file.".local/bin/video_shrink" = { source = ./niri/bin/video_shrink; executable = true; };
    home.file.".local/bin/lite-open" = { source = ./niri/bin/lite-open; executable = true; };
    home.file."POST_INSTALL.txt".source = ./niri/POST_INSTALL.txt;

    # External referenced tools
    home.file.".local/bin/imv-dir-respect" = {
      source = "${inputs.imv-dir-respect}/imv-dir-respect";
      executable = true;
    };

    # Desktop entries
    xdg.desktopEntries.lite-open = {
      name = "Lite-XL Scheme Handler";
      exec = "lite-open %u";
      noDisplay = true;
      terminal = false;
      mimeType = [ "x-scheme-handler/lite-open" ];
    };

    xdg.desktopEntries.imv-dir = {
      name = "imv-dir";
      genericName = "Image viewer";
      comment = "Fast Image Viewer | Open all images in a directory";
      exec = "imv-dir-respect %F";
      noDisplay = true;
      terminal = false;
      categories = [ "Graphics" "2DGraphics" "Viewer" ];
      mimeType = [
        "image/x-farbfeld" "image/tiff" "image/tiff-fx" "image/png" "image/x-png"
        "image/jpeg" "image/jpg" "image/pjpeg" "image/svg+xml" "image/gif"
        "image/bmp" "image/x-bmp" "image/heif" "image/avif" "image/jxl"
        "image/webp" "image/qoi"
      ];
      icon = "multimedia-photo-viewer";
      settings = {
        StartupNotify = "false";
        Keywords = "photo;picture;";
      };
    };

    # Base Desktop packages
    home.packages = with pkgs; [
      adwaita-icon-theme
      alacritty
      foot
      fuzzel
      waybar
      swaybg
      swayosd
      swaynotificationcenter
      wl-clip-persist
      wlsunset
      lxqt.lxqt-policykit
      grim
      slurp
      imv
      mpv
      lite-xl
      btGhostNotePkg
      sox
      libnotify
      wl-clipboard

      # File manager & media utilities
      ffmpeg
      ffmpegthumbnailer
      thunar
      tumbler
      thunar-archive-plugin
    ];
  };
}
