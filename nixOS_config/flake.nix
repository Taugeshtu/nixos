{
  description = "tau's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    imv-dir-respect = {
      url = "github:Taugeshtu/imv-dir-respect";
      flake = false;
    };
    to-day = {
      url = "github:Taugeshtu/TO-DAY";
      flake = false;
    };
    bt-ghost-note = {
      url = "github:Taugeshtu/bt_ghost_note";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@inputs: {
    nixosConfigurations = {

      # Lenovo IdeaPad 5 Pro 16ACH6 — daily driver laptop
      codex = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/codex/default.nix
        ];
      };

      # Microsoft Surface Go 3 — companion tablet
      slate = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          ./hosts/slate/default.nix
        ];
      };

    };
  };
}
