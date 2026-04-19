# GitOps with ArgoCD

## How it Works

ArgoCD continuously watches the `master` branch of this repo. Any change merged to `master` is automatically applied to the cluster — no manual `kubectl apply` needed.

```
git push origin master
       │
       ▼
  ArgoCD detects drift
       │
       ▼
  Applies diff to cluster
  (create / update / prune)
```

## The App-of-Apps Pattern

This repo uses the **App of Apps** pattern: a single root ArgoCD Application (`argocd-apps`) manages a Helm chart whose templates generate all other Application CRDs.

```
argocd-apps (root)
  └── kubernetes/apps/addons/argocd-apps/
        ├── application.yaml    ← bootstraps the root app itself
        ├── values.yaml         ← sets cluster destination
        └── templates/
              ├── addons/argocd.yaml
              ├── homelab/gitea.yaml
              ├── automation/home-assistant.yaml
              └── ... (one file per app)
```

**Bootstrap** — `application.yaml` is the only file that needs to be manually applied once:

```bash
kubectl apply -f kubernetes/apps/addons/argocd-apps/application.yaml
```

After that, every other app in `templates/` is created and managed automatically.

## Application Template

Every app in `templates/<namespace>/<app>.yaml` follows the same pattern — a multi-source ArgoCD `Application` that pulls the upstream Helm chart and overlays values from this repo:

```yaml
# --------------------
# Gitea
#   - Docs: https://gitea.com/
#   - Chart: https://dl.gitea.io/charts (gitea)
# --------------------
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitea
  namespace: {{ .Release.Namespace }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io   # (1)
spec:
  project: default
  sources:
    - repoURL: https://dl.gitea.io/charts
      targetRevision: '>=10 <11'               # (2)
      chart: gitea
      helm:
        valueFiles:
          - $values/kubernetes/apps/homelab/gitea/values.sops.yaml
    - repoURL: git@github.com:afonsoc12/homelab.git
      targetRevision: HEAD
      ref: values                              # (3)
  destination:
    name: {{ .Values.spec.destination.name }}
    namespace: homelab
```

1. Cascade-deletes all owned resources when the Application is deleted.
2. Semver range locks the chart to a major version, allowing Renovate to bump patch/minor automatically.
3. The second source is a `ref` (no path, no chart) — it only provides the values files for the first source.

## Sync Policy

The root `argocd-apps` application has `selfHeal: true` and `prune: true`:

```yaml
syncPolicy:
  automated:
    prune: true      # removes resources deleted from Git
    selfHeal: true   # reverts manual in-cluster changes
  syncOptions:
    - CreateNamespace=true
```

!!! warning "Self-heal"
    Any manual change made directly via `kubectl` will be reverted the next time ArgoCD syncs. All changes must go through Git.

## Useful Commands

```bash
# List all apps and their sync status
argocd app list

# Force sync a specific app
argocd app sync <app-name>

# Sync with pruning (removes orphaned resources)
argocd app sync <app-name> --prune

# Check app details and events
argocd app get <app-name>

# View diff between Git and live state
argocd app diff <app-name>

# Rollback to previous version
argocd app rollback <app-name>
```

## Renovate Integration

[Renovate](https://docs.renovatebot.com/) runs on this repo and automatically opens PRs to:

- Bump Helm chart `targetRevision` in app templates
- Update container image tags in values files

Renovate is configured to ignore `.decrypted~*.yaml` files so it never touches SOPS intermediaries.
