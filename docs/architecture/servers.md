# Servers

## Overview

The homelab spans three physical locations: bare-metal at home, a Raspberry Pi, and an Oracle Cloud VPS — all connected via a Tailscale mesh VPN.

## Server Inventory

| Server | Model | Role | Site | OS | CPU | RAM | Storage |
|--------|-------|------|------|----|-----|-----|---------|
| `k3s-m1` | [Lenovo ThinkCentre M700 Tiny](https://www.lenovo.com/gb/en/p/desktops/thinkcentre/m-series-tiny/thinkcentre-m700/11tc1mtm700) | <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/k3s.png" style="height:1em;vertical-align:middle"> master | 🏠 Home | <img src="https://cdn.simpleicons.org/ubuntu" style="height:1em;vertical-align:middle"> [22.04.5 LTS](https://releases.ubuntu.com/22.04/) | [i5-6500](https://ark.intel.com/content/www/us/en/ark/products/88184/intel-core-i5-6500-processor-6m-cache-up-to-3-60-ghz.html) (4c) | 16 GB | 240 GB SSD |
| `k3s-m2` | [Lenovo ThinkCentre M700 Tiny](https://www.lenovo.com/gb/en/p/desktops/thinkcentre/m-series-tiny/thinkcentre-m700/11tc1mtm700) | <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/k3s.png" style="height:1em;vertical-align:middle"> master | 🇵🇹 PT | <img src="https://cdn.simpleicons.org/ubuntu" style="height:1em;vertical-align:middle"> [22.04.5 LTS](https://releases.ubuntu.com/22.04/) | [i3-6100T](https://ark.intel.com/content/www/us/en/ark/products/90741/intel-core-i3-6100t-processor-3m-cache-3-20-ghz.html) (2c) | 16 GB | 256 GB SSD |
| `k3s-oci-m3` | [Oracle VM.Standard.A1.Flex](https://www.oracle.com/uk/cloud/compute/arm/) | <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/k3s.png" style="height:1em;vertical-align:middle"> master | ☁️ Oracle Cloud | <img src="https://cdn.simpleicons.org/ubuntu" style="height:1em;vertical-align:middle"> [22.04.5 LTS](https://releases.ubuntu.com/22.04/) | ARM Ampere A1 (4c) | 24 GB | 200 GB |
| `rpi-4b` | [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) | <img src="https://cdn.simpleicons.org/docker" style="height:1em;vertical-align:middle"> Docker | 🏠 Home | <img src="https://cdn.simpleicons.org/raspberrypi" style="height:1em;vertical-align:middle"> [OS 13 (Trixie)](https://downloads.raspberrypi.com/raspios_arm64/release_notes.txt) | ARM Cortex-A72 (4c) | 4 GB | 32 GB microSD |
| `rpi-z2w-hyperion` | [Raspberry Pi Zero 2 W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/) | <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/hyperion.png" style="height:1em;vertical-align:middle"> Hyperion | 🏠 Home | <img src="https://cdn.simpleicons.org/raspberrypi" style="height:1em;vertical-align:middle"> OS (TBD) | ARM Cortex-A53 (4c) | 512 MB | 8 GB microSD |
| `hoarder` | TBD | <img src="https://cdn.simpleicons.org/unraid" style="height:1em;vertical-align:middle"> NAS | 🏠 Home | <img src="https://cdn.simpleicons.org/unraid" style="height:1em;vertical-align:middle"> [7.2.4](https://docs.unraid.net/unraid-os/release-notes/7.2.4/) | TBD | 16 GB | 4× 4TB Seagate IronWolf<br>NVMe 1TB |

## Server Roles

### `k3s-m1` — Home Master

Primary K3s control-plane node running at home. Runs the full K3s server stack including the embedded etcd cluster. Part of the `masters` and `k3s_cluster` Ansible groups.

- **Model:** Lenovo ThinkCentre M700 Tiny
- **CPU:** Intel [i5-6500](https://ark.intel.com/content/www/us/en/ark/products/88184/intel-core-i5-6500-processor-6m-cache-up-to-3-60-ghz.html) (4 cores, up to 3.6 GHz)
- **RAM:** 16 GB

### `k3s-m2` — Remote Master

Second K3s control-plane node located in Portugal. Provides geographic redundancy for the control plane. Part of the `masters` and `k3s_cluster` Ansible groups.

- **Model:** Lenovo ThinkCentre M700 Tiny
- **CPU:** Intel [i3-6100T](https://ark.intel.com/content/www/us/en/ark/products/90741/intel-core-i3-6100t-processor-3m-cache-3-20-ghz.html) (2 cores, 3.2 GHz)
- **RAM:** 16 GB

### `k3s-oci-m3` — Oracle Cloud Master

Third K3s control-plane node running on Oracle Cloud Infrastructure (Always Free tier). Connects to the home cluster exclusively via Tailscale.

- **Shape:** `VM.Standard.A1.Flex` — ARM-based Ampere A1 Compute
- **CPU:** 4 OCPUs (ARM Cortex-A76-compatible)
- **RAM:** 24 GB
- **Boot volume:** 200 GB (custom detached boot volume, `prevent_destroy = true`)
- **Region:** UK Cardiff (`uk-cardiff-1`)

See the [Oracle Cloud section](#oracle-cloud-server-k3s-oci-m3) below for DNS quirks specific to this node.

### `rpi-4b` — Raspberry Pi 4B (Docker host)

Runs Docker Compose stacks via the `docker_compose` Ansible role. Not part of k3s-cluster. The `docker` group targets this host specifically.

- **Hardware:** Raspberry Pi 4 Model B (4 GB variant)
- **CPU:** 4× ARM Cortex-A72 @ 1.8 GHz (64-bit)
- **RAM:** 4 GB
- System upgrades are skipped (`skip_system_upgrade: true`) — manual updates only.

Stack definitions live under `docker/rpi-4b/` in the repo (e.g. `adguard/`).

### `rpi-z2w-hyperion` — Raspberry Pi Zero 2 W (LED Controller)

Dedicated Hyperion.ng LED controller for ambient lighting. Runs as a bare-metal service (not part of K3s). Managed by the `hyperion` Ansible role.

- **Hardware:** Raspberry Pi Zero 2 W
- **CPU:** 4× ARM Cortex-A53 @ 1 GHz (64-bit)
- **RAM:** 512 MB
- Hyperion runs as `hyperion@root.service` (root systemd unit). Port 8090.
- System upgrades skipped (`skip_system_upgrade: true`).

### `hoarder` — NAS (Unraid)

Network-attached storage server running Unraid. Provides bulk storage for the homelab. Not part of k3s-cluster; managed in the `unraid` Ansible group. Ansible tasks on this host use `ansible_python_interpreter: /usr/bin/python3`.

- **Storage:** 4× 4TB Seagate IronWolf HDD, 1 parity drive — 12 TB usable

## Ansible Inventory Groups

Defined in `ansible/inventory/hosts.yaml`:

```yaml
masters:
  hosts: k3s-m1, k3s-m2, k3s-oci-m3
nodes:
  hosts: {}                             # K3s agent nodes — currently empty
k3s_cluster:
  children:
    masters:
    nodes:
raspberries:
  hosts: rpi-4b, rpi-z2w-hyperion
docker:
  hosts: rpi-4b
unraid:
  hosts: hoarder
hyperion:
  hosts: rpi-z2w-hyperion
```

## Oracle Cloud Server (`k3s-oci-m3`)

The OCI master runs on Oracle's Always Free tier and is connected to the cluster exclusively via Tailscale. This requires special DNS handling:

!!! warning "Custom resolv.conf required"
    Oracle VMs have a VCN search domain appended to `/etc/resolv.conf`. This causes transient DNS failures inside pods after server restarts.

    **Fix:** create `/etc/k3s-resolv.conf` (without the Oracle search domain) and configure K3s to use it:

    ```yaml
    # /etc/rancher/k3s/config.yaml (on k3s-oci-m3)
    kubelet-arg:
      - "resolv-conf=/etc/k3s-resolv.conf"
    ```

## Tailscale Connectivity

All servers are connected via Tailscale. Server IPs on the Tailscale interface (`tailscale0`) are used for K3s inter-server communication, configured in `ansible/inventory/group_vars/k3s_cluster.sops.yml`:

```yaml
server_config_yaml: |
  node-ip: "{{ ansible_facts['tailscale0']['ipv4']['address'] }}"
```

!!! tip
    This means the cluster continues to work even if the home WAN IP changes, and OCI traffic never touches the public internet.
