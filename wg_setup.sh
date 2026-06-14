#!/bin/bash
# WireGuard offline VPN setup for cross-device ROS 2.
# Usage:
#   ./wg_setup.sh              # Generate all keys and configs
#   ./wg_setup.sh linux <IP>   # (Run on Linux machine) Generate Linux config

set -e
WG_DIR="$(cd "$(dirname "$0")" && pwd)/wg_config"
mkdir -p "$WG_DIR"

gen_keys() {
    local label="$1"
    mkdir -p "$WG_DIR"
    if [ -f "$WG_DIR/${label}_private" ]; then
        echo "  Keys for $label already exist"
        return
    fi
    echo "  Generating keys for $label..."
    docker pull -q linuxserver/wireguard > /dev/null 2>&1 || true
    local tmp
    tmp=$(docker run --rm --entrypoint sh linuxserver/wireguard -c "
        umask 077
        priv=\$(wg genkey)
        echo \"\$priv\"
        echo \"\$priv\" | wg pubkey
    " 2>/dev/null)
    echo "$tmp" | sed -n '1p' > "$WG_DIR/${label}_private"
    echo "$tmp" | sed -n '2p' > "$WG_DIR/${label}_public"
    echo "  Keys saved"
}

case "${1:-all}" in
    mac|all)
        echo "=== Mac Setup ==="
        gen_keys "mac"
        MAC_PRIV=$(cat "$WG_DIR/mac_private")
        MAC_PUB=$(cat "$WG_DIR/mac_public")

        cat > "$WG_DIR/wg0.conf" << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $MAC_PRIV

# Linux peer — add after running 'wg_setup.sh linux'
EOF
        echo "  Mac config: $WG_DIR/wg0.conf"
        echo "  Linux peer public key: $MAC_PUB"
        echo ""
        echo "  Run: ./run_wireguard_sidecar.sh"
        echo "  Then on Linux: ./wg_setup.sh linux 192.168.31.248"
        ;;
    linux)
        if [ -z "$2" ]; then
            echo "Usage: $0 linux <MAC_LAN_IP>"
            echo "  e.g., $0 linux 192.168.31.248"
            exit 1
        fi
        echo "=== Linux Setup ==="
        gen_keys "linux"
        LINUX_PRIV=$(cat "$WG_DIR/linux_private")
        LINUX_PUB=$(cat "$WG_DIR/linux_public")

        if [ ! -f "$WG_DIR/mac_public" ]; then
            echo "ERROR: Copy wg_config/mac_public from Mac first"
            exit 1
        fi
        MAC_PUB=$(cat "$WG_DIR/mac_public")

        sudo tee /etc/wireguard/wg0.conf > /dev/null << EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $LINUX_PRIV

[Peer]
PublicKey = $MAC_PUB
Endpoint = $2:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF
        echo "  Linux config: /etc/wireguard/wg0.conf"
        echo "  Run: sudo wg-quick up wg0"

        echo ""
        echo "=== Add to Mac config ($WG_DIR/wg0.conf) ==="
        echo "[Peer]"
        echo "PublicKey = $LINUX_PUB"
        echo "AllowedIPs = 10.0.0.2/32"
        echo ""
        echo "Then restart the WireGuard sidecar."
        ;;
esac
