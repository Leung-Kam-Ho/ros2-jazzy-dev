# jazzy-docker-cross

ROS 2 Jazzy in Docker (macOS/Docker Desktop) communicating with native ROS 2 on a Linux machine over LAN — fully offline, no cloud services.

## Problem

Docker Desktop for Mac runs containers inside a VM. Containers get private bridge IPs (e.g. 10.88.0.x) that are not directly routable from the LAN. DDS (the ROS 2 discovery protocol) embeds these private IPs in its locator messages, so even with port publishing (`-p`) the Linux side receives wrong addresses and cannot send data back.

## Solution: WireGuard Sidecar

A WireGuard container runs alongside your ROS containers, providing routable tunnel IPs (10.0.0.0/24). All ROS containers share the sidecar's network namespace, so DDS announces the correct tunnel address. The Linux machine connects as a WireGuard peer and communicates over the encrypted tunnel.

```
┌───────────────────── macOS ─────────────────────┐
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │        WireGuard Sidecar                  │    │
│  │  ┌──────────┐  ┌────────────────────┐   │    │
│  │  │   wg0    │  │ Discovery Server   │   │    │
│  │  │ 10.0.0.1 │  │ UDP :11811         │   │    │
│  │  └────▲─────┘  └────────────────────┘   │    │
│  │       │                                   │    │
│  │  ┌────┴─────┐  ┌────────────────────┐   │    │
│  │  │ ROS Node │  │ ROS Node          │   │    │
│  │  │ talker   │  │ listener          │   │    │
│  │  └──────────┘  └────────────────────┘   │    │
│  └──────────────────────────────────────────┘    │
└───────────────────────┬──────────────────────────┘
                        │ WireGuard tunnel :51820
                        │
┌───────────────────────┴──────────┐
│         Linux (native ROS 2)     │
│   wg0: 10.0.0.2                 │
│   ROS_DISCOVERY_SERVER=10.0.0.1 │
└──────────────────────────────────┘
```

ROS containers share the sidecar's network namespace. The discovery server also shares it and listens on `0.0.0.0:11811`. Linux sends discovery traffic to `10.0.0.1:11811` via WireGuard. All DDS data flows through the tunnel — no port publishing, no XML profiles, no NAT hacks needed.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds `r2_jazzy` image from `osrf/ros:jazzy-desktop` |
| `wg_setup.sh` | Generates WireGuard keys and configs (run once) |
| `run_wireguard_sidecar.sh` | Starts the WireGuard sidecar (+ optional discovery server) |
| `run_r2_jazzy.sh` | Launches a ROS container (WireGuard or local mode) |

## Usage

### 1. Build

```bash
docker build -t r2_jazzy .
```

### 2. Generate WireGuard keys

On the Mac:

```bash
./wg_setup.sh
```

This creates `wg_config/` with keys and `wg0.conf` for the Mac sidecar (10.0.0.1).

Copy `wg_config/mac_public` to the Linux machine.

### 3. Start the sidecar

```bash
./run_wireguard_sidecar.sh --with-discovery
```

Starts the WireGuard container (UDP 51820) and a discovery server sharing its network.

### 4. Launch ROS containers

```bash
# Terminal 1
./run_r2_jazzy.sh talker 0

# Terminal 2
./run_r2_jazzy.sh listener 0
```

Containers share the sidecar's network namespace. ROS_DISCOVERY_SERVER defaults to 127.0.0.1:11811.

### 5. Connect the Linux machine

```bash
# On the Linux machine (run as root)
wg_setup.sh linux <MAC_LAN_IP>

# Start WireGuard
sudo wg-quick up wg0

# Use ROS 2 natively
export ROS_DISCOVERY_SERVER=10.0.0.1:11811
export ROS_DOMAIN_ID=0
ros2 run demo_nodes_cpp talker
```

The `wg_setup.sh linux` command generates a Linux config at `/etc/wireguard/wg0.conf`, creates the peer, and prints the `[Peer]` stanza to add to the Mac's `wg_config/wg0.conf`. Add it, then restart the sidecar.

### Local testing (same machine, no WireGuard)

```bash
./run_r2_jazzy.sh talker 0 --local
./run_r2_jazzy.sh listener 0 --local
```

Uses a Docker bridge network (`r2_jazzy_net`) and SUBNET discovery. No sidecar needed.
