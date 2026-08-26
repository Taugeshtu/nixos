# Native heavy workstation & creative applications
{ pkgs, ... }:

{
  home-manager.users.tau = { ... }: {
    home.packages = with pkgs; [
      freecad
      blender
      audacity
      unityhub
    ];
  };
}
