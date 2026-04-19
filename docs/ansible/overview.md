# Ansible Overview

Ansible manages everything below the Kubernetes layer: OS configuration, package installation, k3s installation, Tailscale enrollment, and ongoing node maintenance.

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
| `k3s_cluster` | all k3s nodes (masters + nodes) |
| `masters` | k3s-m1, k3s-m2, k3s-oci-m3 |
| `nodes` | (k3s agent nodes — currently empty) |
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
| `k3s-io/k3s-ansible` | 1.2.0 | k3s installation and upgrade |
| `artis3n.tailscale` | 1.2.1 | Tailscale node enrollment |

Install or update:

```bash
uv run ansible-galaxy collection install -r ansible/requirements.yml
```

## Linting

```bash
uv run ansible-lint
```

Pre-commit hook runs ansible-lint automatically on staged playbooks.
