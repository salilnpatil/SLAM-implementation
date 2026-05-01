# SLAM & Autonomous Navigation — ROS 2 Humble + Gazebo

![ROS 2](https://img.shields.io/badge/ROS_2-Humble-blue?logo=ros)
![Gazebo](https://img.shields.io/badge/Gazebo-11-orange)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)
![License](https://img.shields.io/badge/License-Apache_2.0-green)

A full-stack mobile robotics project implementing **Simultaneous Localization and Mapping (SLAM)** and **autonomous navigation** using ROS 2 Humble. A custom differential-drive robot is built from scratch in URDF/Xacro, equipped with a 360° 2D lidar, and simulated in Gazebo. The SLAM Toolbox generates and serializes occupancy maps; Navigation2 handles autonomous path planning and execution.

<p align="center">
  <img src="asset/slam_demo.gif" alt="SLAM demo" width="720"/>
</p>

---

## Features

- **Custom robot model** — differential-drive chassis defined in modular URDF/Xacro with realistic inertia tensors, a 360° lidar, and Gazebo physics plugins
- **Online async SLAM** — SLAM Toolbox in asynchronous mode for real-time map building with loop-closure detection and Ceres non-linear optimization
- **Pose graph serialization** — maps are saved as `.data`/`.posegraph` files and reloaded for pure localization without re-mapping
- **Navigation2 integration** — full Nav2 stack pre-installed; the twist multiplexer arbitrates between joystick, tracker, and planner velocity commands
- **Gazebo simulation** — obstacle-rich world with calibrated ODE physics, spawned from a single launch command
- **Docker-first workflow** — one `docker-compose up` command brings up the complete ROS 2 + Gazebo + SLAM environment with NVIDIA GPU acceleration and X11 GUI forwarding

---

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Gazebo Simulation                 │
│  ┌───────────────┐        ┌───────────────────────┐ │
│  │  diff_drive   │─/odom─▶│   Robot State         │ │
│  │  plugin       │        │   Publisher (TF tree) │ │
│  └───────┬───────┘        └───────────────────────┘ │
│          │ /scan (LaserScan)                         │
└──────────┼──────────────────────────────────────────┘
           │
    ┌──────▼──────┐       ┌──────────────────────┐
    │ SLAM Toolbox│──map─▶│   RViz 2             │
    │ (async)     │       │   Visualization      │
    └──────┬──────┘       └──────────────────────┘
           │ /map_metadata, /tf (map→odom)
    ┌──────▼──────┐
    │ Navigation2 │──/cmd_vel──▶ twist_mux ──▶ /cmd_vel (robot)
    │ (Nav2 stack)│
    └─────────────┘
```

**TF tree:** `map → odom → base_footprint → base_link → chassis / wheels / lidar`

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Robot framework | ROS 2 Humble |
| Simulation | Gazebo 11 |
| SLAM | SLAM Toolbox (online async, Ceres solver) |
| Navigation | Navigation2 (Nav2) |
| Robot model | URDF / Xacro |
| Containerization | Docker + docker-compose |
| Visualization | RViz 2 |
| Build system | ament_cmake |

---

## Prerequisites

**Option A — Docker (recommended):**
- Docker Engine ≥ 24
- docker-compose ≥ 2
- NVIDIA GPU + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- X11 display server (Linux host)

**Option B — Native:**
- Ubuntu 22.04
- ROS 2 Humble (`ros-humble-desktop-full`)
- `ros-humble-slam-toolbox`
- `ros-humble-navigation2 ros-humble-nav2-bringup`
- `ros-humble-gazebo-ros-pkgs`
- `ros-humble-joint-state-publisher-gui`
- `xacro`

---

## Quick Start

### Docker (recommended)

```bash
# 1. Allow Docker to open GUI windows on the host display
xhost +local:docker

# 2. Build and start the container
docker-compose up --build

# 3. Open a second terminal inside the running container
docker exec -it ros-container bash

# 4. Build the workspace (first run only)
cd ~/dev_ws && colcon build --symlink-install
source install/setup.bash

# 5. Launch the full simulation (Gazebo + robot)
ros2 launch my_bot launch_sim.launch.py
```

### Native ROS 2

```bash
# Clone into your ROS 2 workspace
cd ~/ros2_ws/src
git clone https://github.com/<your-username>/SLAM-implementation.git my_bot

# Install dependencies
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y

# Build
colcon build --symlink-install
source install/setup.bash

# Launch simulation
ros2 launch my_bot launch_sim.launch.py
```

---

## Usage

### 1 — Run the Simulation

```bash
ros2 launch my_bot launch_sim.launch.py
```

Starts Gazebo with the obstacle world and spawns the robot.

### 2 — Start SLAM (mapping mode)

Edit `config/mapper_params_online_async.yaml` and set:

```yaml
mode: mapping
```

Then run SLAM Toolbox:

```bash
ros2 launch slam_toolbox online_async_launch.py \
    params_file:=config/mapper_params_online_async.yaml \
    use_sim_time:=true
```

Drive the robot around with a teleop node to build the map:

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

Save the finished map:

```bash
ros2 run nav2_map_server map_saver_cli -f ~/my_map
```

### 3 — Localization on a Pre-built Map

The repo ships with a pre-generated map. Switch SLAM Toolbox to localization mode (default in `config/mapper_params_online_async.yaml`):

```bash
ros2 launch slam_toolbox online_async_launch.py \
    params_file:=config/mapper_params_online_async.yaml \
    use_sim_time:=true
```

### 4 — Autonomous Navigation with Nav2

```bash
ros2 launch nav2_bringup navigation_launch.py use_sim_time:=true
```

Then use **RViz 2** (`config/drive_bot.rviz`) to set a **2D Nav Goal** and watch the robot plan and execute a path autonomously.

### 5 — Visualization

```bash
# Full driving view
rviz2 -d config/drive_bot.rviz

# SLAM / map building view
rviz2 -d config/slam.rviz
```

---

## Configuration

| File | Purpose |
|------|---------|
| `config/mapper_params_online_async.yaml` | SLAM Toolbox — solver, scan topic, loop-closure thresholds, map file path |
| `config/twist_mux.yaml` | Velocity command priority: joystick (100) > tracker (20) > Nav2 (10) |
| `config/drive_bot.rviz` | RViz layout for navigation and driving |
| `config/slam.rviz` | RViz layout for SLAM mapping |

**Key SLAM parameters:**

| Parameter | Value | Effect |
|-----------|-------|--------|
| `resolution` | `0.05 m` | Map cell size |
| `loop_match_minimum_chain_size` | `10` | Scans required before loop closure attempt |
| `loop_match_minimum_response_fine` | `0.45` | Confidence threshold for accepting a loop closure |
| `minimum_travel_distance` | `0.5 m` | Distance between map updates |

**Map file path** (Docker): the pre-built map is loaded from `/home/ros/my_map` inside the container, matching the volume mount in `docker-compose.yml`.

---

## Project Structure

```
SLAM-implementation/
├── config/
│   ├── mapper_params_online_async.yaml   # SLAM Toolbox parameters
│   ├── twist_mux.yaml                    # Velocity multiplexer config
│   ├── drive_bot.rviz                    # RViz — navigation view
│   ├── slam.rviz                         # RViz — SLAM view
│   └── veiw_bot.rviz                     # RViz — robot inspection view
├── description/
│   ├── robot.urdf.xacro                  # Top-level robot assembly
│   ├── robot_core.xacro                  # Chassis, wheels, caster
│   ├── lidar.xacro                       # 360° 2D lidar sensor
│   ├── gazebo_control.xacro              # Gazebo diff-drive & lidar plugins
│   └── inertial_macros.xacro             # Inertia helper macros
├── launch/
│   ├── launch_sim.launch.py              # Full simulation launch
│   └── rsp.launch.py                     # Robot State Publisher only
├── worlds/
│   └── obstacle.world                    # Gazebo world with box obstacles
├── map/
│   ├── my_map.data                       # Serialized SLAM Toolbox map
│   ├── my_map.posegraph                  # Pose graph for localization
│   ├── my_map_old.pgm                    # Map image (PGM)
│   └── my_map_old.yaml                   # Map metadata
├── asset/
│   └── slam_demo.gif                     # Demo animation
├── Dockerfile                            # ROS 2 Humble image
├── docker-compose.yml                    # GPU-accelerated container setup
├── entrypoint.sh                         # Container entrypoint
├── CMakeLists.txt
└── package.xml
```

---

## Robot Specifications

| Property | Value |
|----------|-------|
| Drive type | Differential drive |
| Chassis | 335 × 265 × 138 mm, 1.0 kg |
| Wheel radius | 50 mm |
| Wheel separation | 350 mm |
| Lidar | 360° ray scan, 0.3–12 m range, 10 Hz |
| Lidar samples | 360 rays / scan |

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
