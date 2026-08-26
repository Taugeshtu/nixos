{ config, lib, pkgs, ... }:

{
  # 1. keyd system service and mappings
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          global = {
            overload_tap_timeout = 500;
          };
          main = {
            leftshift = "layer(leftshift)";
            rightshift = "layer(rightshift)";
            leftcontrol = "layer(leftcontrol)";
            rightcontrol = "layer(rightcontrol)";
            meta = "overload(meta, M-s)";
            rightalt = "overload(rightalt, S-f10)";
            mouse2 = "middlemouse";
            mouse1 = "rightmouse";
          };
          "leftcontrol:C" = {
            leftshift = "overload(leftshift, scrolllock)";
          };
          "leftshift:S" = {
            leftcontrol = "overload(leftcontrol, scrolllock)";
          };
          "rightcontrol:C" = {
            rightshift = "overload(rightshift, scrolllock)";
          };
          "rightshift:S" = {
            rightcontrol = "overload(rightcontrol, scrolllock)";
          };
          "meta:M" = {
            "leftshift+s" = "print";
            t = "clearm(A-t)";
            n = "clearm(A-n)";
          };
          "rightalt:A" = {};
        };
      };
    };
  };

  # 2. Libinput quirks for virtual keyd keyboard integration
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd*keyboard
    AttrKeyboardIntegration=internal
  '';

  # 3. System-wide XKB keyboard layout & ScrollLock layout switch
  services.xserver.xkb = {
    layout = "us,ua";
    options = "grp:sclk_toggle";
  };
}
