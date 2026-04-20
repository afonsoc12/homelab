# Ansible Roles

Local roles live in `ansible/roles/`. External roles and collections are declared in `requirements.yml` and installed via `ansible-galaxy`.

## Local Roles

### `docker`

Manages Docker on `rpi-4b`. Composed of three sub-roles:

| Sub-role | Purpose |
|----------|---------|
| `provision` | Installs Docker, adds user to the `docker` group |
| `daemon-config` | Writes `/etc/docker/daemon.json` from a template |
| `compose` | Clones the compose-files repo and manages Docker Compose stacks |

### `hyperion`

Installs and configures [Hyperion](https://hyperion-project.org/) (ambient LED controller) on `rpi-z2w-hyperion`.

### `k3s`

Thin wrapper around the external `k3s-io/k3s-ansible` collection for cluster-specific overrides.

### `maintenance/update`

Handles `apt` package updates across all servers. Supports layered package lists (base / group / host) via defaults, making it easy to add per-host packages without touching the role.

## External Collections

Declared in `ansible/requirements.yml`. Install or update with:

```bash
uv run ansible-galaxy collection install -r ansible/requirements.yml
```

| Collection | Version | Purpose |
|------------|---------|---------|
| `community.sops` | 2.3.0 | SOPS vars plugin + tasks |
| `community.docker` | 5.2.0 | Docker management on `rpi-4b` |
| `ansible.posix` | 2.1.0 | POSIX utilities |
| `community.general` | 12.6.0 | General-purpose modules |
| `k3s-io/k3s-ansible` | 1.2.0 | k3s installation and upgrade |
| `artis3n.tailscale` | 1.2.1 | Tailscale server enrollment |
