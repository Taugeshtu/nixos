# GitFiend Git GUI client
{ pkgs, ... }:

let
  gitfiend = pkgs.appimageTools.wrapType2 rec {
    pname = "gitfiend";
    version = "0.45.3";
    src = pkgs.fetchurl {
      url = "https://github.com/GitFiend/Support/releases/download/v${version}/GitFiend-${version}.AppImage";
      hash = "sha256-QWR/veNlOA+cbhm/kAZLEbdLheYO3qPkKFTizaK8Aes=";
    };
    extraInstallCommands =
      let
        appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
      in
      ''
        install -m 444 -D ${appimageContents}/gitfiend.desktop $out/share/applications/gitfiend.desktop
        install -m 444 -D ${appimageContents}/gitfiend.png $out/share/icons/hicolor/1024x1024/apps/gitfiend.png
        substituteInPlace $out/share/applications/gitfiend.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=gitfiend'
      '';
  };
in
{
  home-manager.users.tau = { ... }: {
    home.packages = [ gitfiend ];
  };
}
