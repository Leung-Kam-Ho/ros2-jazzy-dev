#!/bin/bash
set -euo pipefail

NAME=${1:-r2_jazzy}
DOMAIN_ID=${2:-0}
DISCOVERY_SERVER=${3:-10.0.0.1}
LOCAL=false

for arg in "$@"; do
    [ "$arg" = "--local" ] && LOCAL=true
done

if [ "$LOCAL" = true ]; then
    docker network inspect r2_jazzy_net >/dev/null 2>&1 || docker network create r2_jazzy_net
    echo "Starting '$NAME' (local mode, domain $DOMAIN_ID)"
    docker run -it --rm \
        --name "$NAME" \
        --network r2_jazzy_net \
        -e DISPLAY=host.docker.internal:0 \
        -e ROS_DOMAIN_ID="$DOMAIN_ID" \
        -e ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET \
        r2_jazzy
else
    echo "Starting '$NAME' (WireGuard mode, domain $DOMAIN_ID)"
    echo "  Discovery server: $DISCOVERY_SERVER:11811"

    mkdir -p /tmp/dds_profiles
    cat > "/tmp/dds_profiles/${NAME}.xml" << EOF
<?xml version="1.0" encoding="UTF-8" ?>
<dds xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
    <profiles>
        <transport_descriptors>
            <transport_descriptor>
                <transport_id>UDPv4Transport</transport_id>
                <type>UDPv4</type>
                <interfaceWhiteList>
                    <address>10.0.0.1</address>
                </interfaceWhiteList>
            </transport_descriptor>
        </transport_descriptors>
        <participant profile_name="wg_interface" is_default_profile="true">
            <rtps>
                <userTransports>
                    <transport_id>UDPv4Transport</transport_id>
                </userTransports>
                <useBuiltinTransports>false</useBuiltinTransports>
            </rtps>
        </participant>
    </profiles>
</dds>
EOF

    docker run -it --rm \
        --name "$NAME" \
        --network container:r2_jazzy_wireguard \
        -e DISPLAY=host.docker.internal:0 \
        -e ROS_DOMAIN_ID="$DOMAIN_ID" \
        -e ROS_DISCOVERY_SERVER="$DISCOVERY_SERVER:11811" \
        -e FASTDDS_BUILTIN_TRANSPORTS=UDPv4 \
        -e FASTRTPS_DEFAULT_PROFILES_FILE=/fastdds_profile.xml \
        -v "/tmp/dds_profiles/${NAME}.xml:/fastdds_profile.xml:ro" \
        r2_jazzy
fi
