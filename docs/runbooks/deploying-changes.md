# Deploying Changes

Five deployment surfaces — each independent, applied in this order when combined:

```
Terraform → Ansible → Bootstrap (once) → Kubernetes → Docker
```

## Quick Reference

| Changed area | What to run |
|-------------|-------------|
| `kubernetes/apps/**` | `git push origin master` |
| `ansible/**` | `uv run ansible-playbook playbooks/<playbook>.yml` |
| `terraform/<module>/**` | `cd terraform/<module> && terraform apply` |
| `docker/<host>/**` | `uv run ansible-playbook playbooks/docker.yml` |
| Fresh cluster | See [Bootstrap](bootstrap.md) |
| K3s upgrade | See [K3s Upgrade](k3s-upgrade.md) |
| New server | See [Adding a Server](adding-server.md) |
| New app | See [Adding an App](adding-app.md) |

---

## Kubernetes

Push to `master` — ArgoCD detects drift and syncs automatically (≤3 min).

```bash
git push origin master
```

!!! warning "No manual kubectl"
    `selfHeal: true` reverts any direct `kubectl` change on next sync. All changes go through Git.

!!! tip "Preview rendered manifests"
    ```bash
    helm secrets template <release> <chart> \
      -f kubernetes/apps/<namespace>/<app>/values.yaml \
      -f kubernetes/apps/<namespace>/<app>/values.sops.yaml
    ```

---

## Ansible

```bash
cd ansible && uv sync   # first time only

uv run ansible-playbook playbooks/k3s-cluster.yml          # cluster config
uv run ansible-playbook playbooks/k3s-cluster.yml --check  # dry-run
uv run ansible-playbook playbooks/k3s-cluster.yml --limit k3s-m1
uv run ansible-playbook playbooks/provision.yml             # all servers
uv run ansible-playbook playbooks/hyperion.yml
```

→ Full playbook reference: [Playbooks](../ansible/playbooks.md)

---

## Bootstrap (Helmfile)

One-time setup on a fresh cluster. Installs the SOPS GPG secret, repo key, ArgoCD, and root app:

```bash
uv run ansible-playbook playbooks/k3s-cluster.yml --tags bootstrap
```

→ Full procedure: [Bootstrap](bootstrap.md)

---

## Terraform

```bash
cd terraform/<module>
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend
terraform init -backend-config=../.decrypted~backend.sops.tfbackend  # first time
terraform plan && terraform apply
rm ../.decrypted~backend.sops.tfbackend
```

| Module | Manages |
|--------|---------|
| `cloudflare/` | DNS, tunnel, WAF |
| `adguard/` | DNS rewrites, blocklists |
| `mariadb/` / `postgres/` | Databases and users |
| `oci/` | Oracle Cloud compute |
| `backblaze/` | B2 buckets |

!!! warning "Never commit `.decrypted~*` files"

→ Full details: [Terraform Overview](../terraform/overview.md)

---

## Docker

Docker Compose stacks on `rpi-4b` are managed by Ansible. Stack files live under `docker/rpi-4b/`.

```bash
uv run ansible-playbook playbooks/docker.yml
```
