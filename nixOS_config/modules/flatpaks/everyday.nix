# Everyday lightweight Flatpak applications
{ ... }:

{
  services.flatpak.packages = [
    "com.usebottles.bottles"
    "de.haeckerfelix.Fragments"
    "com.github.PintaProject.Pinta"
    "no.mifi.losslesscut"
  ];
}
