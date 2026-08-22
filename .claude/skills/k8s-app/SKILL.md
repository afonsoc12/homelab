---
name: k8s-app
description: Add a new application or service to the homelab cluster. Trigger when the user wants to deploy a new app, add a new service, set up an ingress for an external device, or wire up a new tool to ArgoCD. Covers both k3s apps (full ArgoCD Application) and external services (bare metal, Docker, Unraid) via the external-ingress ApplicationSet.
---

# Adding an App

## k3s app (runs in cluster)

1. Create exactly one values file — never both:
   ```
   kubernetes/apps/<namespace>/<app>/values.yaml       # no secrets needed
   kubernetes/apps/<namespace>/<app>/values.sops.yaml  # secrets needed — holds ALL values (config + secrets), not just the secret keys
   ```

2. Create ArgoCD Application:
   ```
   kubernetes/apps/addons/argocd-apps/templates/<namespace>/<app>.yaml
   ```
   Follow the multi-source pattern in existing templates — upstream chart as source 1, this repo as `ref: values` source 2.
   `valueFiles` always includes the global `secrets://../../apps/values.sops.yaml`, plus exactly one per-app file (`../../apps/<namespace>/<app>/values.yaml` or `secrets://../../apps/<namespace>/<app>/values.sops.yaml`) — never both for the same app.

3. Add a bookmark link to `kubernetes/apps/homelab/glance/values.yaml` (`configmap.data."home.yml"` → Homelab page → the relevant bookmarks group). Use `icon: di:<slug>` (dashboard-icons, matches the slug used in `docs/services/*.md`) and the app's actual ingress host as `url`.

4. Push — ArgoCD auto-syncs within ~3 min.

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

4. Add a bookmark link to `kubernetes/apps/homelab/glance/values.yaml` (same as step 3 for k3s apps above).

## Runbook

Full details: `@docs/runbooks/adding-app.md`
