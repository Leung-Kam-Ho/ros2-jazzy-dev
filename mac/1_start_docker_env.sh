#!/bin/bash
# Move to the root directory where docker-compose.yml is located
cd "$(dirname "$0")/.."

echo "Starting ROS 2 and Zenoh Bridge containers..."
docker-compose up -d --build
echo "Containers started successfully. You can now run the talker or listener scripts."
