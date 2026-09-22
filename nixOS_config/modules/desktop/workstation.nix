# Native heavy workstation & creative applications
{ pkgs, ... }:

{
  imports = [
    ./gitfiend.nix
  ];

  home-manager.users.tau = { ... }: {
    home.packages = with pkgs; [
      freecad
      blender
      audacity
      unityhub
    ];
  };
}
