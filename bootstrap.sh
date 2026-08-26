#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
ENCRYPTED_KEY="$SCRIPT_DIR/nixOS_config/bootstrap/keys.age"

echo "========================================"
echo " NixOS Bootstrap & Disaster Recovery"
echo "========================================"

# --- Stage 1: Secret Key Recovery ---
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo ""
    echo ">> Stage 1: Restoring Age master key from head password..."
    if [ -f "$ENCRYPTED_KEY" ]; then
        mkdir -p "$AGE_KEY_DIR"
        nix shell nixpkgs#age -c age -d "$ENCRYPTED_KEY" > "$AGE_KEY_FILE"
        chmod 600 "$AGE_KEY_FILE"
        echo ">> Master Age key restored to $AGE_KEY_FILE"
    else
        echo "Error: $ENCRYPTED_KEY not found!" >&2
        exit 1
    fi
else
    echo ">> Stage 1: Age key already present at $AGE_KEY_FILE"
fi

# --- Stage 2: System Rebuild ---
echo ""
echo ">> Stage 2: Applying NixOS system configuration..."
sudo nixos-rebuild switch --flake "$SCRIPT_DIR/nixOS_config#codex"

# --- Stage 3: Future Binaries Post-Install ---
echo ""
echo ">> Stage 3: Building local development binaries (_Future)..."
FUTURE_DIR="$HOME/10_PROJECTS/_Future"
mkdir -p "$HOME/.local/bin"

if [ -d "$FUTURE_DIR" ]; then
    # 1. Purse & Purse-Niri
    if [ -d "$FUTURE_DIR/Purse" ]; then
        echo "Building Purse..."
        (cd "$FUTURE_DIR/Purse" && cargo build --release -p purse -p purse-niri && cp target/release/purse target/release/purse-niri "$HOME/.local/bin/")
    fi

    # 2. lsp-broker
    if [ -d "$FUTURE_DIR/lsp-broker" ]; then
        echo "Building lsp-broker..."
        (cd "$FUTURE_DIR/lsp-broker" && cargo build --release && cp target/release/lsp-broker "$HOME/.local/bin/")
    fi

    # 3. Current
    if [ -d "$FUTURE_DIR/Current" ]; then
        echo "Building Current..."
        (cd "$FUTURE_DIR/Current" && cargo build --release && cp target/release/current "$HOME/.local/bin/")
    fi
    echo ">> Future binaries built and installed into ~/.local/bin"
else
    echo ">> _Future directory not found, skipping local cargo builds."
fi

echo ""
echo "========================================"
echo " Bootstrap complete! System operational."
echo "========================================"
