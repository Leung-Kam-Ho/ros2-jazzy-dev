#!/bin/bash
# Load environment variables from .env if it exists
if [ -f "$(dirname "$0")/../.env" ]; then
    export $(grep -v '^#' "$(dirname "$0")/../.env" | xargs)
fi

echo "Starting ROS 2 Listener on Native Linux (Domain ID: ${ROS_DOMAIN_ID:-0})..."
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ros2 run demo_nodes_cpp listener
