# Cluster Bootstrap

Full procedure for bootstrapping a fresh cluster from scratch.

## Prerequisites

- PGP key `47E4999BED565F9874AA0E7C05DA03D000FC10D1` in local GPG keyring
- `kubectl` configured against the target cluster
- `helmfile` installed
- `helm-secrets` plugin installed (`helm plugin install https://github.com/jkroepke/helm-secrets`)
- `uv` installed (Python deps)

Verify helm-secrets is set up:

```bash
helm plugin list        # should show secrets
helm secrets version
helmfile version
```

## Steps

### 1 — Provision servers (Ansible)

Installs k3s, Tailscale, and configures all nodes. Skips bootstrap (that's step 2):

```bash
uv sync
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --skip-tags bootstrap
```

### 2 — Bootstrap ArgoCD (Ansible + Helmfile)

Runs `kubernetes/bootstrap/helmfile.yaml` via Ansible — exports the GPG key from the local keyring and passes it to Helmfile:

```bash
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags bootstrap
```

Helmfile applies releases in dependency order:

| Release | What |
|---------|------|
| `homelab-sops-gpg` | GPG private key secret — ArgoCD uses this to decrypt SOPS values at sync time |
| `homelab-repo` | SSH deploy key — ArgoCD uses this to pull from GitHub (SOPS-encrypted) |
| `argocd` | ArgoCD itself via the [argo-cd Helm chart](https://argoproj.github.io/argo-helm) |
| `argocd-apps` | Root ArgoCD Application — triggers the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative) |

Once `argocd-apps` is applied, ArgoCD syncs all remaining apps from `master` automatically.

#### Helmfile internals

- `secrets:` key — uses `helm-secrets` to decrypt SOPS-encrypted values files before passing to Helm
- `values:` with `.gotmpl` suffix — processed as Go templates by Helmfile (used for `homelab-sops-gpg` to inject `SOPS_GPG_KEY` env var)
- `helmfile diff` shows what would change without applying

```bash
# Preview changes without applying
SOPS_GPG_KEY=$(gpg --export-secret-keys --armor 47E4999BED565F9874AA0E7C05DA03D000FC10D1) \
  helmfile diff -f kubernetes/bootstrap/helmfile.yaml
```

### 3 — Provision external infrastructure (Terraform)

Only needed if Cloudflare DNS, OCI compute, or other external infra is not yet set up:

```bash
cd terraform/<module>
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend
terraform init -backend-config=../.decrypted~backend.sops.tfbackend
terraform apply
rm ../.decrypted~backend.sops.tfbackend
```

See [Terraform overview](../terraform/overview.md) for details.

## Re-running bootstrap

The bootstrap play is idempotent — safe to re-run. Helmfile only upgrades releases when values change.

```bash
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags bootstrap
```

## App of Apps pattern

`argocd-apps` is the root Application. It points ArgoCD at `kubernetes/apps/addons/argocd-apps/` which is a Helm chart whose `templates/` generate all other ArgoCD Application CRDs — one per service. This is the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative).

```
argocd-apps (root, applied by bootstrap)
  └── kubernetes/apps/addons/argocd-apps/templates/
        ├── addons/argocd.yaml        ← ArgoCD manages itself from here on
        ├── homelab/mealie.yaml
        ├── automation/home-assistant.yaml
        └── ...
```

After bootstrap, the Helmfile `argocd` release is superseded — ArgoCD self-manages its own upgrades via `templates/addons/argocd.yaml`. Renovate opens PRs to bump the chart version there.
