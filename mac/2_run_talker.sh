#!/bin/bash
echo "Starting ROS 2 Talker on Mac (Docker)..."
docker exec -it ros2_jazzy_node bash -c "source /opt/ros/jazzy/setup.bash && export RMW_IMPLEMENTATION=rmw_fastrtps_cpp && ros2 run demo_nodes_cpp talker"
