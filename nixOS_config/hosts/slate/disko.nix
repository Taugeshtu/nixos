{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [ "subvol=@root" "compress=zstd" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "subvol=@nix" "compress=zstd" "noatime" ];
                    };
                    "@home" = {
                      mountpoint = "/home/tau";
                      mountOptions = [ "subvol=@home" "compress=zstd" ];
                    };
                    "@cache" = {
                      mountpoint = "/cache";
                      mountOptions = [ "subvol=@cache" "compress=zstd" ];
                    };
                    "@var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "subvol=@var_log" "nodatacow" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
