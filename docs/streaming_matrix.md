# Tower Multi-Monitor & Streaming Matrix

## 1. Tower Display Architecture

- **Monitor 1 (Vertical)**: Dedicated Kiosk status dashboard (always visible, unprivileged).
- **Monitor 2 (Horizontal)**: Dynamic context-switched output:
  1. **Codex Stream (Highest Priority)**: If Codex beams into Tower via Sunshine/Moonlight, display Codex screen.
  2. **Tower Local Session**: If Tower was unlocked locally, display tau session viewer.
  3. **Kiosk Default**: Black / slideshow / greeter screen when locked.
- **Virtual Output (Headless)**: Dynamically rendered by tau's Niri compositor upon unlock. Sunshine captures this output for remote streaming.

---

## 2. Usage Scenarios

| Scenario | Trigger | Codex Runs | Tower Runs | Monitor 2 State |
|---|---|---|---|---|
| **A: Game / Compute Stream** | Codex starts Moonlight to Tower | Moonlight (client) | Tau Niri renders to headless virtual output → Sunshine encodes | Black / Unobservable |
| **B: Codex Big Screen** | Codex triggers Waybar mirror button | Sunshine (server) | Kiosk launches Moonlight connecting to Codex | Displays Codex Screen |
| **C: Local Physical Work** | Tau logs in locally at Tower Kiosk | N/A | Kiosk attaches Wayland viewer to tau's headless virtual output | Displays Tau Desktop |

---

## 3. NixOS Service Components

- `modules/services/sunshine.nix` — Outbound low-latency display encoder / server.
- `modules/services/moonlight.nix` — Inbound client / mirror receiver.
- Waybar integration for one-click streaming triggers.
