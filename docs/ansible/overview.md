# Ansible Overview

Ansible manages everything below the Kubernetes layer: OS configuration, package installation, K3s installation, Tailscale enrollment, and ongoing server management.

## Setup

This project uses [uv](https://docs.astral.sh/uv/) for Python dependency management. All Ansible dependencies (including the `ansible` package itself) are declared in `pyproject.toml`.

```bash
# Install all dependencies into a local venv
uv sync

# Run any ansible command through uv
uv run ansible <args>
uv run ansible-playbook <args>
uv run ansible-lint
```

## Configuration (`ansible.cfg`)

```ini
[defaults]
stdout_callback = ansible.builtin.default
result_format   = yaml          # YAML output for readability
inventory       = inventory/hosts.yaml
roles_path      = roles

# SOPS vars plugin — decrypts *.sops.yaml inventory vars on the fly
vars_plugins_enabled = host_group_vars,community.sops.sops

host_key_checking    = False
interpreter_python   = auto_silent
```

The `community.sops.sops` vars plugin is what makes SOPS-encrypted inventory variables (`hosts_secrets.sops.yaml`) transparent — Ansible decrypts them automatically before each run.

## Inventory Structure

```
ansible/inventory/
├── hosts.yaml                         # Host and group definitions
├── hosts_secrets.sops.yaml            # Encrypted: ansible_host, ansible_user, SSH keys
└── group_vars/
    ├── k3s_cluster.sops.yml           # k3s version, cluster token, node config
    └── all/
        └── vars.yml                   # Non-secret group variables
```

### Host Groups

| Group | Members |
|-------|---------|
| `k3s_cluster` | all K3s nodes (masters + nodes) |
| `masters` | k3s-m1, k3s-m2, k3s-oci-m3 |
| `nodes` | (K3s agent nodes — currently empty) |
| `raspberries` | rpi-4b, rpi-z2w-hyperion |
| `docker` | rpi-4b |
| `unraid` | hoarder |
| `hyperion` | rpi-z2w-hyperion |

## Collections

Declared in `ansible/requirements.yml`:

| Collection | Version | Purpose |
|------------|---------|---------|
| `community.sops` | 2.2.7 | SOPS vars plugin + tasks |
| `community.docker` | 5.1.0 | Docker management on rpi-4b |
| `ansible.posix` | 2.1.0 | POSIX utilities |
| `community.general` | 12.5.0 | General-purpose modules |
| `k3s-io/k3s-ansible` | 1.2.0 | K3s installation and upgrade |
| `artis3n.tailscale` | 1.2.1 | Tailscale server enrollment |

Install or update:

```bash
uv run ansible-galaxy collection install -r ansible/requirements.yml
```

### Roles

Galaxy roles install to `~/.local/share/ansible/roles` (outside the repo). Custom roles live in `ansible/roles/` and are committed. The `roles_path` in `ansible.cfg` covers both:

```bash
uv run ansible-galaxy role install -r ansible/requirements.yml
```

## `maintenance` Role

Runs on every server via all playbooks (no tags required). Handles:

### SSH Hardening (`sshd_config.j2`)

Deployed to `/etc/ssh/sshd_config` on every run. Key settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| `PasswordAuthentication` | `no` | Keys only |
| `PermitRootLogin` | `no` | No direct root access |
| `AllowUsers` | `{{ ansible_user }}` | Only the inventory-defined user per host |
| `MaxAuthTries` | `3` | Disconnect after 3 failed attempts |
| `MaxStartups` | `3:50:10` | Rate-limit pre-auth connections: allow 3, drop 50% above that, hard cap 10 |
| `ClientAliveInterval` | `300` | Keepalive every 5 min |
| `ClientAliveCountMax` | `3` | Disconnect after ~15 min idle |
| `AllowTcpForwarding` | `yes` | Port forwarding (tunnels) |
| `AllowAgentForwarding` | `no` | Block agent forwarding (hijack risk) |
| `LogLevel` | `VERBOSE` | Log key fingerprints on auth |

Config is validated with `sshd -t` before the service restarts.

### inotify Limits

Sets `fs.inotify.max_user_watches` and `fs.inotify.max_user_instances` via sysctl — required for K3s and file-watching tools.

### Package Management (tag: `update`)

Only runs with `--tags update`. Runs `apt dist-upgrade`, installs base/group/host packages, cleans up, and reboots if required.

## `hyperion` Role

Installs and manages Hyperion.ng on `rpi-z2w-hyperion`. Installs via `apt`, disables the per-user systemd unit, and runs the service as root (`hyperion@root.service`). Validates port 8090 is reachable after start.

## `docker_compose` Role

Deploys Docker Compose stacks to hosts in the `docker` group (`rpi-4b`) and `unraid` group (`hoarder`). Stack definitions live under `docker/<inventory_hostname>/` at the repo root (e.g. `docker/rpi-4b/adguard/`, `docker/hoarder/decide/`). The role syncs each stack directory to the host, ensures volume directories exist, and manages the compose lifecycle.

Full guide, including all the Unraid-specific gotchas below: `.claude/skills/unraid-docker/SKILL.md`.

### Unraid DockerMan Templates

For hosts in the `unraid` group, the role additionally renders one DockerMan XML template per compose service into `/boot/config/plugins/dockerMan/templates-user/`, so containers deployed via `docker_compose_v2` show up as native, editable apps in the Unraid GUI (icon, WebUI link, port/volume/env fields) instead of "unmanaged" containers.

Compose stays the single source of truth for the container spec (image, ports, volumes, environment, labels). An optional `unraid.yml` sidecar file per stack supplies fields the compose spec has no equivalent for — icon, WebUI URL, category, overview, per-field descriptions/display-tier, and which env vars to mask as secrets in the GUI:

```yaml
# docker/hoarder/<stack>/unraid.yml
<service-name>:                # keyed by compose service name
  icon: https://example.com/icon.png
  webui: "http://[IP]:[PORT:8081]/"
  category: "Tools: Network:Web"
  overview: "Short description shown in the Unraid GUI."
  project_url: https://example.com/repo   # optional, -> <Project>
  support_url: https://example.com/issues # optional, -> <Support>
  license: MIT                            # optional, -> <License>
  env_descriptions:
    SOME_API_KEY: "Shown under the field in the edit form."
  env_display:
    SOME_API_KEY: advanced   # 'always' (default) or 'advanced'
  secret_env:
    - SOME_API_KEY            # masked in the DockerMan edit form, value never shown
```

If `unraid.yml` is omitted, sane defaults are used. For non-secret vars, the rendered XML's `Default`/inner text is the actual value from the compose file (so the GUI shows real current config, not blanks) — except vars listed in `secret_env`, which are always left empty in the XML even though the running container has the real value (from `.env`, mode `0600`, generated from `secrets.sops.yaml`).

**Gotchas learned the hard way (full detail in the skill file):**

- Containers need the `net.unraid.docker.managed=dockerman` label to show as *editable* in the GUI — the role injects it automatically into every service on unraid hosts, but a manually-run `docker compose up` outside Ansible won't have it.
- Fresh Unraid boxes may have **no Python at all** — bootstrap with `un-get install python3` (see skill file) before the first run.
- Unraid's own management nginx squats `:8080` on every interface — check `ss -tlnp` on the host before picking a host port for a new stack.
- PUID/PGID convention on Unraid is `99:100` (`nobody:users`), not an arbitrary app-specific UID — match the host's own data ownership.

To add a new native-looking container on Unraid: create `docker/hoarder/<stack>/docker-compose.yaml` (+ optional `secrets.sops.yaml` and `unraid.yml`), then run the `unraid.yml` playbook.

## Linting

```bash
uv run ansible-lint
```

Pre-commit hook runs ansible-lint automatically on staged playbooks.
