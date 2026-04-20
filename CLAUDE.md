# homelab

GitOps-driven homelab managed with ArgoCD (Kubernetes), Ansible, and Terraform.

## Repo Layout

```
kubernetes/       # Kubernetes manifests (GitOps via ArgoCD)
  apps/
    addons/argocd-apps/templates/<ns>/  # ArgoCD Application CRDs (one .yaml per app)
    <namespace>/<app>/                  # App Helm values (values.yaml / values.sops.yaml)
  charts/         # Ad-hoc Kubernetes resource charts
ansible/          # k3s cluster provisioning and server management
terraform/        # Cloudflare, OCI, Backblaze B2
docs/             # Full documentation (see below)
```

## Secrets

All secrets are SOPS-encrypted. **Never commit plaintext secrets.**

- Ansible: `community.sops.sops` vars plugin — `inventory/hosts_secrets.sops.yaml`
- Terraform: `carlpett/sops` provider — `secrets.sops.yaml` per module; `backend.sops.tfbackend`
- Kubernetes: ArgoCD references `values.sops.yaml` alongside plain `values.yaml`

See @docs/secrets.md for full details.

## Documentation

Detailed docs live under `docs/`. Keep them up to date when changing the areas they cover. Also, use the following files if you need further context.

| Topic | Doc |
|-------|-----|
| Architecture & servers | @docs/architecture/overview.md, @docs/architecture/servers.md, @docs/architecture/networking.md |
| Kubernetes namespaces | @docs/kubernetes/namespaces.md |
| ArgoCD setup | @docs/kubernetes/argocd.md |
| Ansible setup & commands | @docs/ansible/overview.md |
| Ansible playbooks | @docs/ansible/playbooks.md |
| Terraform modules & commands | @docs/terraform/overview.md |
| All services | @docs/services/ |
| Runbooks (adding app, adding server, k3s upgrade) | @docs/runbooks/ |

## Quick Commands

### Ansible
```bash
uv sync                                              # install deps
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml
uv run ansible-lint
```
→ Full details: @docs/ansible/overview.md

### Terraform
```bash
cd terraform/<module>
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend
terraform init -backend-config=../.decrypted~backend.sops.tfbackend
terraform plan && terraform apply
```
→ Full details: @docs/terraform/overview.md

### Kubernetes / ArgoCD
Push to `master` — ArgoCD auto-syncs. To force:
```bash
argocd app sync <app-name>
```
→ Adding a new app: @docs/runbooks/adding-app.md
