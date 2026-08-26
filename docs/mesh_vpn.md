# Mesh Networking & SSH Trust Model

## 1. Self-Hosted Headscale on Orbital

- Control plane and custom DERP relay hosted on Orbital VPS (`orbital.priv`).
- Tailscale client installed on Codex and Tower pointing to Orbital Headscale server URL.
- Zero third-party telemetry, end-to-end WireGuard encryption, automatic NAT traversal.
- Mesh survives temporary Orbital outages for established peer-to-peer tunnels.

---

## 2. SSH Access & Routing Matrix

| From | To | Purpose | Key Location | Protection Level |
|---|---|---|---|---|
| Codex-tau | Tower-tau | Full shell / admin / unlock | Codex `/home/tau/.ssh/` | Encrypted (Vault) |
| Codex-tau | Tower-kiosk | Trigger Moonlight (restricted cmd) | Codex `/home/tau/.ssh/` | Encrypted (Vault) → forced command only |
| Tower-tau | Codex-tau | Reverse access (optional) | Tower `/home/tau/.ssh/` | Encrypted (Vault) |
| Codex-tau | Orbital | VPS management | Codex `/home/tau/.ssh/` | Encrypted (Vault) |
| Tower-tau | Orbital | VPS management | Tower `/home/tau/.ssh/` | Encrypted (Vault) |
| Codex-kiosk | Orbital | Phone-home on boot | Codex System partition | Unencrypted ⚠️ forced command, revocable |
| Tower-kiosk | Orbital | Phone-home on boot | Tower System partition | Unencrypted ⚠️ forced command, revocable |

---

## 3. Threat & Compromise Model

- **Hardware Theft (Codex or Tower)**:
  - Kiosk keys are unencrypted but restricted to specific forced commands and revocable on Orbital.
  - Tau user keys and secrets are behind LUKS2 encryption and unreadable while powered off or locked.
  - Revoking the Headscale node key on Orbital cuts the stolen machine from the private mesh immediately.
- `@todo: consider Orbital compromise threat also`
