#!/bin/bash
set -e

echo "Stopping all running Docker containers..."
if [ "$(docker ps -q)" ]; then
    docker stop $(docker ps -q)
    echo "All containers stopped."
else
    echo "No containers are currently running."
fi
