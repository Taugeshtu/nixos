# Gaming packages
{ pkgs, ... }:

{
  home-manager.users.tau = { ... }: {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
