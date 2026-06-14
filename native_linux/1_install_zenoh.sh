#!/bin/bash
cd "$(dirname "$0")"

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "Downloading Zenoh DDS Bridge for x86_64 (amd64)..."
    curl -L -o zenoh-bridge-dds.zip https://github.com/eclipse-zenoh/zenoh-plugin-dds/releases/download/1.0.2/zenoh-plugin-dds-1.0.2-x86_64-unknown-linux-gnu-standalone.zip
elif [ "$ARCH" = "aarch64" ]; then
    echo "Downloading Zenoh DDS Bridge for aarch64 (arm64)..."
    curl -L -o zenoh-bridge-dds.zip https://github.com/eclipse-zenoh/zenoh-plugin-dds/releases/download/1.0.2/zenoh-plugin-dds-1.0.2-aarch64-unknown-linux-gnu-standalone.zip
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

sudo apt-get install -y unzip
unzip -o zenoh-bridge-dds.zip
chmod +x zenoh-bridge-dds

echo "Zenoh DDS Bridge installed locally!"
