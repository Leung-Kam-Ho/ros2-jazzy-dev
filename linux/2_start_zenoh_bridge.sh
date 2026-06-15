#!/bin/bash
# Load environment variables from .env if it exists
if [ -f "$(dirname "$0")/../.env" ]; then
    export $(grep -v '^#' "$(dirname "$0")/../.env" | xargs)
fi

cd "$(dirname "$0")"

if [ ! -f "./zenoh-bridge-ros2dds" ]; then
    echo "zenoh-bridge-ros2dds not found. Please run 1_install_zenoh.sh first."
    exit 1
fi

echo "Starting Zenoh ROS2 Bridge on Native Linux (Domain ID: ${ROS_DOMAIN_ID:-0})..."
export RUST_LOG=info
./zenoh-bridge-ros2dds --listen tcp/0.0.0.0:7447 peer # --config ../zenoh_config.json
