{ config, pkgs, lib, osConfig ? null, ... }:

let
  hostName = if osConfig != null then osConfig.networking.hostName else "codex";
  hostKeySecret = "id_ed25519_${hostName}";
in
{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/tau/.config/sops/age/keys.txt";

    secrets."ssh_config" = {
      path = "/home/tau/.ssh/config";
    };

    secrets.${hostKeySecret} = {
      path = "/home/tau/.ssh/id_ed25519";
    };
  };
}
