# Servers

## Overview

The homelab spans three physical locations: bare-metal at home, a Raspberry Pi, and an Oracle Cloud VPS — all connected via a Tailscale mesh VPN.

## Server Inventory

| Server | Role | Site | OS |
|--------|------|------|----|
| `k3s-m1` | k3s master | 🏠 Home | Ubuntu 22.04 LTS |
| `k3s-m2` | k3s master | 🇵🇹 PT | Ubuntu 22.04 LTS |
| `k3s-oci-m3` | k3s master | ☁️ Oracle Cloud | Ubuntu 22.04 LTS |
| `rpi-4b` | k3s worker + Docker host | 🏠 Home | Ubuntu 24.04 LTS |
| `rpi-z2w-hyperion` | LED controller (Hyperion) | 🏠 Home | Ubuntu 24.04 LTS |
| `hoarder` | NAS / storage | 🏠 Home | Unraid |

## Ansible Inventory Groups

Defined in `ansible/inventory/hosts.yaml`:

```yaml
masters:        # k3s-m1, k3s-m2, k3s-oci-m3  (k3s control plane)
nodes:          # (k3s agent nodes — currently empty)
k3s_cluster:    # masters + nodes
raspberries:    # rpi-4b, rpi-z2w-hyperion
docker:         # rpi-4b (also runs Docker directly)
unraid:         # hoarder
hyperion:       # rpi-z2w-hyperion
```

## Oracle Cloud Server (`k3s-oci-m3`)

The OCI master runs on Oracle's Always Free tier and is connected to the cluster exclusively via Tailscale. This requires special DNS handling:

!!! warning "Custom resolv.conf required"
    Oracle VMs have a VCN search domain appended to `/etc/resolv.conf`. This causes transient DNS failures inside pods after server restarts.

    **Fix:** create `/etc/k3s-resolv.conf` (without the Oracle search domain) and configure k3s to use it:

    ```yaml
    # /etc/rancher/k3s/config.yaml (on k3s-oci-m3)
    kubelet-arg:
      - "resolv-conf=/etc/k3s-resolv.conf"
    ```

## Tailscale Connectivity

All servers are connected via Tailscale. Server IPs on the Tailscale interface (`tailscale0`) are used for k3s inter-server communication, configured in `ansible/inventory/group_vars/k3s_cluster.sops.yml`:

```yaml
server_config_yaml: |
  node-ip: "{{ ansible_facts['tailscale0']['ipv4']['address'] }}"
```

!!! tip
    This means the cluster continues to work even if the home WAN IP changes, and OCI traffic never touches the public internet.
