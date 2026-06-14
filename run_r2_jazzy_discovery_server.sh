#!/bin/bash
# Starts a Fast DDS discovery server for cross-device ROS 2 communication.
# Usage: ./run_r2_jazzy_discovery_server.sh
# Run this on one machine first, then connect containers from any device.

HOST_IP=$(ipconfig getifaddr en0 2>/dev/null || \
          hostname -I 2>/dev/null | awk '{print $1}' || \
          ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo "Discovery server running on $HOST_IP:11811"

docker run -it --rm \
    --name r2_jazzy_discovery_server \
    --network r2_jazzy_net \
    -p 11811:11811/udp \
    r2_jazzy \
    fastdds discovery -i 0 -l 0.0.0.0 -p 11811

