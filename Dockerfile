FROM osrf/ros:jazzy-desktop
RUN echo 'export DISPLAY=host.docker.internal:0' >> ~/.bashrc
