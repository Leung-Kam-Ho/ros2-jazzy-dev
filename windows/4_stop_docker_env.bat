@echo off
cd /d "%~dp0\.."
echo Stopping ROS 2 and Zenoh Bridge containers...
docker-compose down
echo Containers stopped.
pause
