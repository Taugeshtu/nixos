# Communications & Chat Flatpak applications
{ ... }:

{
  services.flatpak.packages = [
    "com.ktechpit.whatsie"
    "com.viber.Viber"
    "org.telegram.desktop"
    "io.github.milkshiift.GoofCord"
    "com.discordapp.Discord"
    "org.kde.neochat"
  ];
}
