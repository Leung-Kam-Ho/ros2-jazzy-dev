# Completely Offline Cross-Platform ROS 2 (Jazzy) via Zenoh

This repository solves the problem of connecting ROS 2 nodes running in Docker on Mac/Windows to Native Linux machines over a local network, **completely offline**, without Tailscale, VPNs, or complex DDS XML configurations.

It bypasses Docker Desktop's lack of real bridge mode by tunneling DDS multicast traffic over standard TCP using `zenoh-bridge-dds`.

## Project Structure

We've organized the workflow into simple scripts for each platform:

```
├── .env                  # Configuration (Linux IP, Domain ID)
├── docker-compose.yml    # Docker setup for Mac/Windows
├── Dockerfile            # ROS 2 Jazzy image definition
├── mac/                  # Scripts for MacOS
│   ├── 1_start_docker_env.sh
│   ├── 2_run_talker.sh
│   ├── 3_run_listener.sh
│   └── 4_stop_docker_env.sh
├── windows/              # Scripts for Windows
│   ├── 1_start_docker_env.bat
│   ├── 2_run_talker.bat
│   ├── 3_run_listener.bat
│   └── 4_stop_docker_env.bat
└── native_linux/         # Scripts for Native Linux
    ├── 1_install_zenoh.sh
    ├── 2_start_zenoh_bridge.sh
    ├── 3_run_talker.sh
    └── 4_run_listener.sh
```

## How It Works

1. **Native Linux** acts as the server. It runs the standalone `zenoh-bridge-dds` binary, listening on TCP port `7447`. It captures all local DDS multicast traffic and forwards it.
2. **Mac / Windows Docker** acts as the client. Docker Compose starts a ROS 2 container (`network_mode: "host"`) alongside a Zenoh Bridge container. The bridge connects *out* of the Docker VM to the Linux machine's IP, tunneling the DDS traffic.
3. Both sides are forced to use `RMW_IMPLEMENTATION=rmw_fastrtps_cpp` to ensure 100% vendor compatibility.

---

## Step 1: Initial Setup (All Platforms)

1. Clone this repository.
2. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Open `.env` and replace `192.168.x.x` with the actual **Local IPv4 Address of your Native Linux machine**.

---

## Step 2: Native Linux Setup

Run the following scripts from the `native_linux` folder on your Linux machine:

1. **Install Zenoh** (Downloads the correct architecture binary: amd64 or arm64):
   ```bash
   ./native_linux/1_install_zenoh.sh
   ```
2. **Start the Zenoh Bridge** (Keep this running in a terminal):
   ```bash
   ./native_linux/2_start_zenoh_bridge.sh
   ```

---

## Step 3: Mac or Windows Setup

Open a terminal (Mac) or Command Prompt/PowerShell (Windows) and run the scripts in your respective folder.

### On Mac:
1. Start the Docker environment:
   ```bash
   ./mac/1_start_docker_env.sh
   ```

### On Windows:
1. Start the Docker environment:
   ```cmd
   windows\1_start_docker_env.bat
   ```

---

## Step 4: Testing Bidirectional Communication

You can test communication in both directions using the provided scripts.

**Test 1: Mac/Windows Talker ➡️ Linux Listener**
1. On Linux, run: `./native_linux/4_run_listener.sh`
2. On Mac, run: `./mac/2_run_talker.sh` (or `windows\2_run_talker.bat` on Windows)
3. You should see `Hello World` appearing on the Linux listener!

**Test 2: Linux Talker ➡️ Mac/Windows Listener**
1. On Mac, run: `./mac/3_run_listener.sh` (or `windows\3_run_listener.bat` on Windows)
2. On Linux, run: `./native_linux/3_run_talker.sh`
3. You should see `Hello World` appearing on the Mac/Windows listener!

---

## Step 5: Shutting Down

When you are finished, gracefully stop your Docker containers.

**On Mac:**
```bash
./mac/4_stop_docker_env.sh
```

**On Windows:**
```cmd
windows\4_stop_docker_env.bat
```
