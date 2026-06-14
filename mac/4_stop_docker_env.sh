#!/bin/bash
cd "$(dirname "$0")/.."
echo "Stopping ROS 2 and Zenoh Bridge containers..."
docker-compose down
echo "Containers stopped."
