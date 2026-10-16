# Stage 01: Secrets Recovery & Fleet Join

This document brings the installed machine into full fleet membership with unlocked secrets and active mesh networking.

---

## 1. First Boot & User Login

1. Boot the machine from the internal drive.
2. Log in as user `tau` with the password set during installation.
   - If using default `initialPassword = "nixos"`, change it now via `passwd`.
   - **Codex & Tower Note**: If updating `tau`'s password, update the LUKS Vault passphrase to match (`sudo cryptsetup luksChangeKey /dev/disk/by-partlabel/vault`), or the Greetd PAM unlock hook will fail on next boot.
3. Verify network connection (`nmcli` or GUI applet).

---

## 2. Clone Configuration to Home

Clone the repository into the standard project hot path:

```bash
mkdir -p ~/10_PROJECTS
git clone https://github.com/Taugeshtu/nixOS.git ~/10_PROJECTS/nixOS
cd ~/10_PROJECTS/nixOS/nixOS_config
```

---

## 3. Secret Key Recovery (Age Master Key)

Your base system packages already include `age`. Restore the master key from your head password:

```bash
mkdir -p ~/.config/sops/age
age -d ./bootstrap/keys.age > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

*(Enter your master passphrase when prompted).*

---

## 4. Activate SOPS Secrets

Trigger the user-level `sops-nix` service to decrypt secrets into memory:

```bash
systemctl --user restart sops-nix.service
```

Verify that your SSH keys and config are now present:
```bash
ls -l ~/.ssh/
```
You should see your host identity key (`id_ed25519_<host>`) and `config` symlinked.

---

## 5. Verify System Rebuild

Now that secrets are decrypted and your host identity key is active in `~/.ssh/`, verify that `nixos-rebuild` evaluates and switches cleanly:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

*(Replace `<host>` with `codex`, `tower`, or `slate`).*

---

## 6. Join the Fleet Mesh

Authenticate the machine onto the Tailscale mesh overlay:

```bash
sudo tailscale up --login-server https://orbital.tau.games
```

Verify you can reach other online fleet nodes:
```bash
tailscale status
```

Proceed to [02_postinstall.md](./02_postinstall.md).
