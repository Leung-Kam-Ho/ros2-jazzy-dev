#!/bin/bash
echo "Starting ROS 2 Listener on Native Linux..."
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ros2 run demo_nodes_cpp listener
