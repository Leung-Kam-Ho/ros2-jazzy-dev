#!/bin/bash
set -euo pipefail

WG_DIR="$(cd "$(dirname "$0")" && pwd)/wg_config"

if [ ! -f "$WG_DIR/wg0.conf" ]; then
    echo "No config found. Run ./wg_setup.sh first."
    exit 1
fi

WITH_DISCOVERY=false
for arg in "$@"; do
    [ "$arg" = "--with-discovery" ] && WITH_DISCOVERY=true
done

docker rm -f r2_jazzy_wireguard 2>/dev/null || true

docker run -d --rm \
    --name r2_jazzy_wireguard \
    --cap-add NET_ADMIN \
    --cap-add SYS_MODULE \
    -v "$WG_DIR/wg0.conf:/config/wg0.conf:ro" \
    -p 51820:51820/udp \
    linuxserver/wireguard

echo "WireGuard sidecar started (tunnel IP: 10.0.0.1)"

if [ "$WITH_DISCOVERY" = true ]; then
    docker rm -f r2_jazzy_discovery_server 2>/dev/null || true
    docker run -d --rm \
        --name r2_jazzy_discovery_server \
        --network container:r2_jazzy_wireguard \
        r2_jazzy \
        fastdds discovery -i 0 -l 0.0.0.0 -p 11811
    echo "Discovery server started (10.0.0.1:11811)"
fi

echo ""
echo "ROS containers (Mac): ./run_r2_jazzy.sh <name> <domain> 127.0.0.1"
echo "Linux native:         sudo wg-quick up wg0"
echo "                     export ROS_DISCOVERY_SERVER=10.0.0.1:11811"
echo "                     export ROS_DOMAIN_ID=0"
