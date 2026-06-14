FROM osrf/ros:jazzy-desktop
RUN apt-get update && apt-get install -y net-tools iproute2 && rm -rf /var/lib/apt/lists/*
RUN echo 'export DISPLAY=host.docker.internal:0' >> ~/.bashrc
