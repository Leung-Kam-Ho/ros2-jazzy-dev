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

SESSION_NAME="zenoh-bridge"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "tmux is not installed. Running in normal mode..."
    ./2_start_zenoh_bridge.sh
    exit
fi

# Start tmux session
echo "Starting Zenoh ROS2 Bridge in tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" "export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}; export RUST_LOG=info; ./zenoh-bridge-ros2dds --listen tcp/0.0.0.0:7447 peer"
tmux attach-session -t "$SESSION_NAME"
