@echo off
echo Starting ROS 2 Listener on Windows (Docker)...
docker exec -it ros2_jazzy_node bash -c "source /opt/ros/jazzy/setup.bash && export RMW_IMPLEMENTATION=rmw_fastrtps_cpp && ros2 run demo_nodes_cpp listener"
pause
