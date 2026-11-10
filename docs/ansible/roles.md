# Ansible Roles

Local roles live in `ansible/roles/`. External roles and collections are declared in `requirements.yml` and installed via `ansible-galaxy`.

## Local Roles

### `docker_compose`

Deploys Docker Compose stacks on `rpi-4b` and Unraid. Stack sources live in `docker/<hostname>/` — one subdirectory per stack. The role:

1. Finds all stack directories for the target host under `docker/{{ inventory_hostname }}/`
2. Syncs stack files to `~/homelab/docker/<stack>/` on the host (excluding secrets)
3. Decrypts `secrets.sops.yaml` → `.env` on the host (mode `0600`)
4. Creates any required Docker networks
5. Fetches missing pinned images before reconciling containers moved between Unraid stacks
6. Deploys independent services first, then repairs stale or invalid shared network namespaces before starting dependents
7. Creates tools with `restart: "no"` without starting them
8. Prunes unused images, preserving images referenced by stopped containers
9. On Unraid, writes native `my-<container>.xml` templates and an ordered autostart list; retires the legacy Compose boot script

**Stack layout:**

```
docker/
└── rpi-4b/
    └── <stack-name>/
        ├── docker-compose.yaml
        ├── secrets.sops.yaml   # encrypted → deployed as .env
        └── ...                 # any other files synced as-is
```

**Key defaults** (`roles/docker_compose/defaults/main.yml`):

| Variable | Default | Purpose |
|----------|---------|---------|
| `docker_compose_base_dir` | `~/homelab/docker` | Deploy target on host |
| `docker_compose_volumes_dir` | `/opt/docker` | Persistent volume root |
| `docker_compose_stacks_src` | `../../docker` (relative to playbook) | Stack source dir |
| `docker_compose_networks` | `{}` | Extra Docker networks to create |
| `docker_compose_recreate_policy` | `auto` | When to recreate containers |

Docker itself is installed separately by the `geerlingguy.docker` external role (see `docker.yml` playbook).

### `hyperion`

Installs and configures [Hyperion](https://hyperion-project.org/) (ambient LED controller) on `rpi-z2w-hyperion`.

Hyperion rejects non-local (cross-VLAN) connections while its password is still the
factory default, with no config flag to disable this. Fixed by changing the password
via Hyperion's websocket API, not by this role.

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
| `k3s-io/k3s-ansible` | 1.2.0 | K3s installation and upgrade |
| `artis3n.tailscale` | 1.2.1 | Tailscale server enrollment |
