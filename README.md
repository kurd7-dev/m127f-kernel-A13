# Yad Kernel (SM-M127F)

## Overview

This is a custom Android kernel built for the Samsung Galaxy M12 (SM-M127F). The goal of this project is to provide a stable, feature-rich kernel with modern capabilities such as Docker support, improved debugging, and a cleaner development workflow.

This project started from a basic booting kernel and evolved into a fully working environment capable of running containers directly on Android.

---

## Important Notice

* **Do NOT use the `dev` branch for daily use.**
* The `dev` branch is experimental and may contain unstable or incomplete changes.
* Always use the **`stable` branch** for flashing and daily usage.

---

## Features

###  Core Kernel

* Successfully boots on SM-M127F
* Clean build system
* Modular and test-friendly workflow

###  Docker Support

Full Docker support has been implemented and validated on-device.

#### Enabled Kernel Configs

* Namespaces (PID, NET, IPC, UTS, USER)
* Cgroups (CPU, memory, pids, freezer, blkio, cpuset)
* Netfilter and iptables support
* OverlayFS (recommended storage driver)
* VETH, bridge, VLAN, macvlan support
* Device Mapper support

#### Verified Functionality

* `dockerd` runs successfully on Android
* Containers run (tested with Alpine)
* Networking works (ping + internet access)
* Overlay2 storage driver working



