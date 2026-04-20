# homelab

GitOps-driven homelab managed with ArgoCD (Kubernetes), Ansible, and Terraform.

## Architecture

```
kubernetes/       # Kubernetes manifests (GitOps via ArgoCD)
  apps/
    addons/argocd-apps/   # Master Helm chart that generates all ArgoCD Application CRDs
      templates/<ns>/     # One .yaml per app, one folder per namespace
    <namespace>/<app>/    # App-specific Helm values (values.yaml or values.sops.yaml)
  charts/               # Ad-hoc Kubernetes resource charts (not ArgoCD apps)
ansible/              # k3s cluster provisioning and node management
terraform/            # Cloudflare DNS/tunnels, Authentik, MariaDB, Hostinger, Backblaze B2, OCI
cloudflare/           # (non-Terraform) Cloudflare configs
```

### Kubernetes Namespaces

| Namespace | Contents |
|-----------|----------|
| `addons` | ArgoCD, cert-manager, MetalLB, Reflector |
| `automation` | Home Assistant, ESPHome, Zigbee2MQTT, Node-RED, n8n, Mosquitto |
| `databases` | PostgreSQL, MariaDB, Redis, InfluxDB |
| `homelab` | Gitea, Mealie, Ghostfolio, Firefly, FreshRSS, Glance, Romm, etc. |
| `ingress` | Authentik, Authelia, LLDAP, ingress-nginx, Cloudflared, Wireguard |
| `longhorn-system` | Longhorn storage |
| `monitoring` | Grafana, Loki, Prometheus stack, Alloy, Uptime Kuma, ntfy |
| `sandbox` | Experimental apps |

## Cluster Nodes

Defined in `ansible/inventory/hosts.yaml`; secrets in `inventory/hosts_secrets.sops.yaml`.

- **k3s masters**: `k3s-m1`, `k3s-m2`, `k3s-oci-m3` (Oracle Cloud, Tailscale-connected)
- **Raspberries**: `rpi-4b`, `rpi-z2w-hyperion`
- **Unraid/NAS**: `hoarder`

## Secrets

All secrets are SOPS-encrypted (`.sops.yaml` files). Never commit plaintext secrets.

- Ansible: `community.sops.sops` vars plugin — inventory secrets in `inventory/hosts_secrets.sops.yaml`
- Terraform: `carlpett/sops` provider — `secrets.sops.yaml` per module; backend in `backend.sops.tfbackend`
- Kubernetes: ArgoCD apps reference `values.sops.yaml` alongside plain `values.yaml`

## Commands

### Ansible

```bash
# Install/update dependencies
uv sync

# Run cluster playbook
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml

# Ad-hoc
uv run ansible-playbook ansible/playbooks/<playbook>.yml
uv run ansible -m ping all
uv run ansible-lint   # lint playbooks
```

### Terraform

```bash
# Must decrypt backend config first (via SOPS), then:
cd terraform/cloudflare
terraform init -backend-config=../.decrypted~backend.sops.tfbackend
terraform plan
terraform apply

# Other modules: authentik, hostinger, mariadb, backblaze, oci — same pattern

# View sensitive outputs (e.g. rotated B2 application keys)
terraform output -raw longhorn_application_key
terraform output -raw velero_application_key
```

### Terraform Modules

| Module | Manages |
|--------|---------|
| `cloudflare` | DNS records, tunnels, WAF, zone settings |
| `oci` | Oracle Cloud compute instance (`k3s-oci-m3`) and networking |
| `backblaze` | B2 buckets (`ac-longhorn`, `ac-terraform`, `ac-velero`) and scoped application keys |

### Kubernetes / ArgoCD

Changes are applied automatically via ArgoCD GitOps (push to `master` → ArgoCD syncs).

```bash
# Force sync an app
argocd app sync <app-name>

# Check sync status
argocd app list
```

## Adding a New App

1. Create `kubernetes/apps/<namespace>/<app>/values.yaml` (and `values.sops.yaml` if secrets needed)
2. Add ArgoCD Application manifest at `kubernetes/apps/addons/argocd-apps/templates/<namespace>/<app>.yaml`
3. Reference chart from upstream Helm repo or local chart
4. Commit and push — ArgoCD auto-syncs

See existing apps (e.g. `templates/homelab/gitea.yaml`) for the Application template pattern with multi-source (upstream chart + values from this repo).

## Renovate

Renovate is configured to auto-update:
- Helm chart versions in ArgoCD app templates
- Container image tags in kubernetes manifests
- Ignores `.decrypted~*.yaml` files

## Key Files

- `kubernetes/apps/addons/argocd-apps/application.yaml` — bootstraps the argocd-apps chart itself
- `kubernetes/apps/addons/argocd-apps/values.yaml` — sets `spec.destination.name` for all apps
- `ansible/ansible.cfg` — sets inventory path, SOPS vars plugin, YAML stdout callback
- `terraform/cloudflare/terraform.tf` — S3 backend config (Cloudflare R2 or compatible)
