#!/bin/bash
set -euo pipefail

NAME=${1:-r2_jazzy}
DOMAIN_ID=${2:-0}
DISCOVERY_SERVER=${3:-10.0.0.1}
LOCAL=false

for arg in "$@"; do
    [ "$arg" = "--local" ] && LOCAL=true
done

if [ "$LOCAL" = true ]; then
    docker network inspect r2_jazzy_net >/dev/null 2>&1 || docker network create r2_jazzy_net
    echo "Starting '$NAME' (local mode, domain $DOMAIN_ID)"
    docker run -it --rm \
        --name "$NAME" \
        --network r2_jazzy_net \
        -e DISPLAY=host.docker.internal:0 \
        -e ROS_DOMAIN_ID="$DOMAIN_ID" \
        -e ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET \
        r2_jazzy
else
    echo "Starting '$NAME' (WireGuard mode, domain $DOMAIN_ID)"
    echo "  Discovery server: $DISCOVERY_SERVER:11811"

    docker run -it --rm \
        --name "$NAME" \
        --network container:r2_jazzy_wireguard \
        -e DISPLAY=host.docker.internal:0 \
        -e ROS_DOMAIN_ID="$DOMAIN_ID" \
        -e ROS_DISCOVERY_SERVER="$DISCOVERY_SERVER:11811" \
        -e FASTDDS_BUILTIN_TRANSPORTS=UDPv4 \
        r2_jazzy
fi
