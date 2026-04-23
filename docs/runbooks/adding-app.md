# Adding a New App

Adding a new app to the cluster is a two-step process: create the values file, then create the ArgoCD Application manifest. ArgoCD does the rest.

## Step 1 — Create the Values File

Create a directory for your app under the appropriate namespace:

```
kubernetes/apps/<namespace>/<app>/
├── values.yaml          # plain Helm values
└── values.sops.yaml     # encrypted secrets (if needed)
```

**Example:** adding `myapp` to the `homelab` namespace:

```bash
mkdir -p kubernetes/apps/homelab/myapp
```

```yaml
# kubernetes/apps/homelab/myapp/values.yaml
image:
  repository: ghcr.io/owner/myapp
  tag: "1.2.3"      # always pin — never use latest

ingress:
  enabled: true
  hosts:
    - host: myapp.yourdomain.com
      paths:
        - path: /
```

If the app needs secrets:

```bash
# Create and encrypt the secrets file
sops kubernetes/apps/homelab/myapp/values.sops.yaml
```

## Step 2 — Create the ArgoCD Application

Create a manifest under `templates/<namespace>/`:

```bash
# kubernetes/apps/addons/argocd-apps/templates/homelab/myapp.yaml
```

```yaml
# --------------------
# My App
#   - Docs: https://myapp.io/
#   - Chart: https://charts.myapp.io (myapp)
# --------------------
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: {{ .Release.Namespace }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  sources:
    - repoURL: https://charts.myapp.io
      targetRevision: 1.2.3
      chart: myapp
      helm:
        valueFiles:
          - $values/kubernetes/apps/homelab/myapp/values.yaml
          # - $values/kubernetes/apps/homelab/myapp/values.sops.yaml  # uncomment if secrets exist
    - repoURL: git@github.com:afonsoc12/homelab.git
      targetRevision: HEAD
      ref: values
  destination:
    name: {{ .Values.spec.destination.name }}
    namespace: homelab
```

## Step 3 — Commit and Push

```bash
git add kubernetes/apps/homelab/myapp/ \
        kubernetes/apps/addons/argocd-apps/templates/homelab/myapp.yaml
git commit -m "feat: add myapp to homelab namespace"
git push
```

ArgoCD will detect the new Application within its polling interval (default: 3 minutes) and sync it automatically.

You can also trigger an immediate sync:

```bash
argocd app sync argocd-apps   # re-renders the root chart first
argocd app sync myapp          # then sync the new app
```

---

## Notes

!!! tip "Chart version pinning"
  Pin `targetRevision` to an exact chart version (for example `1.2.3`). Renovate will open PRs with explicit version bumps, keeping upgrades reviewable and reproducible.

!!! warning "No `latest` tags"
    Always pin image tags. Using `latest` makes deployments non-reproducible and breaks GitOps rollback.

!!! info "Namespace auto-creation"
    The `CreateNamespace=true` sync option is set globally on `argocd-apps`. New namespaces are created automatically — no need to pre-create them.

!!! info "SOPS in values"
    ArgoCD decrypts `values.sops.yaml` files on the fly using the cluster's SOPS key. The plain `values.sops.yaml` content is never exposed in the UI — only the rendered Helm output is visible.
