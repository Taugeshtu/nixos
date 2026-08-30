# PAM hook & LUKS Vault unlock script for Tower
{ pkgs, lib, config, ... }:

let
  unlockScript = pkgs.writeShellScriptBin "unlock-vault" ''
    exec >> /var/log/unlock_debug.log 2>&1
    set -x
    echo "=== unlock-vault started at $(${pkgs.coreutils}/bin/date) for user $PAM_USER ==="

    # If called via PAM for another user, skip
    if [ -n "$PAM_USER" ] && [ "$PAM_USER" != "tau" ]; then
      echo "Not user tau (PAM_USER=$PAM_USER), exiting."
      exit 0
    fi

    VAULT_DEV="/dev/disk/by-partlabel/VAULT"
    if [ ! -e "$VAULT_DEV" ]; then
      VAULT_DEV="/dev/nvme0n1p2"
    fi
    MAPPER="/dev/mapper/nvme_vault"

    # 1. Unlock LUKS volume if not already opened
    if [ ! -e "$MAPPER" ]; then
      if [ -e "$VAULT_DEV" ]; then
        echo "=== Opening LUKS Vault ==="
        # If PAM authtok is available on stdin, strip trailing null byte and open
        if [ ! -t 0 ]; then
          ${pkgs.coreutils}/bin/tr -d '\0' | ${pkgs.cryptsetup}/bin/cryptsetup open "$VAULT_DEV" nvme_vault --key-file -
        else
          ${pkgs.cryptsetup}/bin/cryptsetup open "$VAULT_DEV" nvme_vault
        fi
      else
        echo "Vault volume $VAULT_DEV not found, skipping..."
        exit 0
      fi
    fi

    # 2. Mount /home/tau subvolume
    if ! ${pkgs.util-linux}/bin/mountpoint -q /home/tau; then
      ${pkgs.coreutils}/bin/mkdir -p /home/tau
      ${pkgs.util-linux}/bin/mount -t btrfs -o subvol=@home,compress=zstd "$MAPPER" /home/tau
      ${pkgs.coreutils}/bin/chown tau:users /home/tau
    fi

    # 3. Mount /cache subvolume
    if ! ${pkgs.util-linux}/bin/mountpoint -q /cache; then
      ${pkgs.coreutils}/bin/mkdir -p /cache
      ${pkgs.util-linux}/bin/mount -t btrfs -o subvol=@cache,compress=zstd "$MAPPER" /cache
      ${pkgs.coreutils}/bin/chown tau:users /cache
    fi

    # 4. Ensure /cache/tmp exists and is accessible to nixbld
    ${pkgs.coreutils}/bin/mkdir -p /cache/tmp
    ${pkgs.coreutils}/bin/chmod 1777 /cache/tmp
    if ! ${pkgs.util-linux}/bin/findmnt -M /tmp | ${pkgs.gnugrep}/bin/grep -q '/cache/tmp'; then
      ${pkgs.util-linux}/bin/mount --bind /cache/tmp /tmp
    fi

    # 5. Mount MergerFS for ~/K
    if ! ${pkgs.util-linux}/bin/mountpoint -q /home/tau/K; then
      ${pkgs.coreutils}/bin/mkdir -p /home/tau/K /home/tau/.source-dirs/K /home/tau/.bigK
      ${pkgs.mergerfs}/bin/mergerfs -o defaults,allow_other,cache.files=off,dropcacheonclose=false,func.getattr=newest,category.create=epff,uid=1000,gid=100 /home/tau/.source-dirs/K:/home/tau/.bigK /home/tau/K
    fi

    # 6. Activate encrypted disk swap if present
    if [ -f /cache/swapfile ]; then
      ${pkgs.util-linux}/bin/swapon --priority 10 /cache/swapfile 2>/dev/null || true
    fi

    echo "=== Vault unlocked and mounted successfully ==="
  '';
in
{
  environment.systemPackages = [
    pkgs.cryptsetup
    pkgs.util-linux
    pkgs.coreutils
    pkgs.mergerfs
    unlockScript
  ];

  # PAM hook: automatically unlock vault when tau authenticates
  security.pam.services.greetd.text = lib.mkDefault ''
    # Account & auth
    auth     requisite pam_nologin.so
    auth     required  pam_unix.so     try_first_pass nullok
    auth     requisite pam_exec.so     seteuid expose_authtok stdout ${unlockScript}/bin/unlock-vault
    account  required  pam_unix.so
    session  required  pam_unix.so
    session  required  pam_env.so      conffile=/etc/pam/environment readenv=0
    session  optional  ${pkgs.systemd}/lib/security/pam_systemd.so
  '';
}
