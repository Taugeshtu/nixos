{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/tau/.config/sops/age/keys.txt";

    secrets."id_ed25519_github" = {
      path = "/home/tau/.ssh/id_ed25519_github";
    };

    secrets."id_ed25519_oxford" = {
      path = "/home/tau/.ssh/id_ed25519_oxford";
    };

    secrets."id_ed25519_vps" = {
      path = "/home/tau/.ssh/id_ed25519_vps";
    };

    secrets."ssh_config" = {
      path = "/home/tau/.ssh/config";
    };
  };
}
