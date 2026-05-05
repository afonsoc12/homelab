---
name: k8s-app
description: Add a new application or service to the homelab cluster. Trigger when the user wants to deploy a new app, add a new service, set up an ingress for an external device, or wire up a new tool to ArgoCD. Covers both k3s apps (full ArgoCD Application) and external services (bare metal, Docker, Unraid) via the external-ingress ApplicationSet.
---

# Adding an App

## k3s app (runs in cluster)

1. Create values file:
   ```
   kubernetes/apps/<namespace>/<app>/values.yaml
   kubernetes/apps/<namespace>/<app>/values.sops.yaml  # if secrets needed
   ```

2. Create ArgoCD Application:
   ```
   kubernetes/apps/addons/argocd-apps/templates/<namespace>/<app>.yaml
   ```
   Follow the multi-source pattern in existing templates — upstream chart as source 1, this repo as `ref: values` source 2.

3. Push — ArgoCD auto-syncs within ~3 min.

## External service (bare metal, Docker, Unraid)

1. Add IP to `@kubernetes/apps/values.sops.yaml`:
   - LAN devices → `ips` map
   - Tailscale devices → `ips_tailscale` map
   - Keys use dashes: `rpi-4b`, `wled-kitchen`
   - Dashed keys need `index` syntax in templates: `{{ index .Values.ips "rpi-z2w" }}`

2. Create values file:
   ```
   kubernetes/apps/homelab/external-ingress/<app>/values.yaml
   ```
   Reference existing files (e.g. `@kubernetes/apps/homelab/external-ingress/adguard/values.yaml`) for the shape. Labels use dashes.

3. Add to ApplicationSet generators list in `@kubernetes/apps/addons/argocd-apps/templates/homelab/external-ingress.yaml` — append `- app: <app-name>` to `elements`.

## Runbook

Full details: `@docs/runbooks/adding-app.md`
