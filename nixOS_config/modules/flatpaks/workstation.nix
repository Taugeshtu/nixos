# Workstation / Creative Flatpak applications
{ ... }:

{
  services.flatpak.packages = [
    "com.obsproject.Studio"
    "com.bambulab.BambuStudio"
    "com.boxy_svg.BoxySVG"
    "org.onlyoffice.desktopeditors"
  ];
}
