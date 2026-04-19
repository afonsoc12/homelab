# Playbook Reference

All playbooks live in `ansible/playbooks/`. Run them with:

```bash
uv run ansible-playbook ansible/playbooks/<playbook>.yml [--tags <tag>]
```

---

## `k3s-cluster.yml` — Main Cluster Playbook

The primary playbook for managing the k3s cluster. Runs in plays:

| Play | Hosts | Tags | Description |
|------|-------|------|-------------|
| Update packages | `k3s_cluster` | `update` | `apt upgrade` on all nodes |
| Connect to Tailscale | `k3s_cluster` | *(always)* | Enroll / re-enroll nodes in Tailscale |
| k3s prerequisites | `k3s_cluster` | *(always)* | System prereqs: inotify, multipath, sysctl |
| Configure multipath | `k3s_cluster` | *(always)* | Longhorn multipath blacklist in `/etc/multipath.conf` |
| Setup k3s nodes | `nodes` | *(always)* | Install k3s agent on worker nodes |
| Reset cluster | `k3s_cluster` | `reset` | Full uninstall of k3s (destructive — never tagged) |
| Reboot masters | `masters` | `reboot` | Rolling reboot of masters (serial: 1) |
| Reboot nodes | `nodes` | `reboot` | Reboot all agent nodes |
| Upgrade k3s masters | `masters` | `upgrade` | Rolling upgrade (serial: 1) |
| Upgrade k3s nodes | `nodes` | `upgrade` | Upgrade all agent nodes |

### Common invocations

```bash
# Full cluster run (prereqs + tailscale)
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml

# Update packages only
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags update

# Rolling k3s upgrade (see runbook for full procedure)
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags upgrade

# Rolling reboot of masters only
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags reboot --limit masters
```

!!! danger "`--tags reset`"
    The `reset` tag **completely uninstalls k3s** from all nodes. It is tagged `never` — it will not run unless explicitly passed with `--tags reset`. Use only for full cluster teardown.

---

## `provision.yml` — Node Provisioning

General-purpose provisioning: package updates and Tailscale for all node types.

| Play | Hosts | Tags |
|------|-------|------|
| Update packages | `all:!unraid` | `update` |
| Connect to Tailscale | `all` | `tailscale` |

```bash
# Provision all nodes
uv run ansible-playbook ansible/playbooks/provision.yml

# Tailscale only
uv run ansible-playbook ansible/playbooks/provision.yml --tags tailscale

# Update packages, skip Unraid
uv run ansible-playbook ansible/playbooks/provision.yml --tags update
```

---

## `docker.yml` — Docker Host Management

Manages Docker-based services on `rpi-4b` (which also runs Docker alongside k3s).

```bash
uv run ansible-playbook ansible/playbooks/docker.yml
```

---

## `hyperion.yml` — LED Controller

Manages the Hyperion LED controller on `rpi-z2w-hyperion`.

```bash
uv run ansible-playbook ansible/playbooks/hyperion.yml
```

---

## Ad-hoc Commands

```bash
# Ping all hosts
uv run ansible -m ping all

# Run a command on all k3s nodes
uv run ansible k3s_cluster -m command -a "kubectl get nodes"

# Check disk usage on all masters
uv run ansible masters -m command -a "df -h"

# Gather facts from a single host
uv run ansible k3s-m1 -m setup
```
