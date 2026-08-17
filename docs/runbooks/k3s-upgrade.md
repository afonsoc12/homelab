# Runbook: K3s Upgrade

!!! warning "Never skip minor versions"
    Kubernetes version skew requires upgrading one minor version at a time (e.g. `1.33 → 1.34`, not `1.33 → 1.35`).

## 1. Pull the Latest Repo State

Always start from an up-to-date checkout — stale SOPS files, playbooks, or inventory can cause the upgrade to diverge from what's actually deployed:

```bash
git pull
```

## 2. Check the Current Cluster Version

Check the version actually running on the cluster — do not trust the `k3s_version` value in SOPS alone, it can drift from what's live if a previous bump wasn't applied:

```bash
kubectl --context=k3s-cluster get nodes -o wide
```

## 3. Find the Target Version

Find the latest patch for the target minor (one minor above the version from step 1):

```bash
curl -s "https://api.github.com/repos/k3s-io/k3s/releases?per_page=50" \
  | jq -r '.[].tag_name' \
  | grep '^v1\.34\.' \
  | grep -v '\-rc' \
  | head -1
```

## 4. Review the Changelog

Read the release notes for the target version (and any intermediate patch releases within the same minor you're skipping) before upgrading. Check for:

- Breaking changes / deprecated APIs
- Changes to default flags or component config
- Known upgrade issues reported against the release

```bash
# Fetch release notes for the target tag
curl -s "https://api.github.com/repos/k3s-io/k3s/releases/tags/<target-tag>" | jq -r '.body'
```

!!! warning "Flag any concerns before proceeding"
    If the changelog mentions breaking changes, deprecated flags in use by this cluster, or known bugs affecting Longhorn/MetalLB/cert-manager/Tailscale, stop and address them (or get sign-off) before continuing to the snapshot step.

## 5. Snapshot etcd (Required for Rollback)

!!! warning "Ensure Tailscale is up"
    All masters must be reachable — confirm Tailscale is running on your machine (`tailscale status`) before proceeding. `k3s-m2` and `k3s-oci-m3` are only reachable over the tailnet; without it, Ansible will time out connecting to them.

```bash
# Run on one of the masters
sudo k3s etcd-snapshot save --name "pre-upgrade-v1.34.x-$(date -Iseconds)"
```

Verify the snapshot was created:

```bash
sudo k3s etcd-snapshot list
```

## 6. Update the Version in SOPS

```bash
sops ansible/inventory/group_vars/k3s_cluster.sops.yml
# Update: k3s_version: vX.Y.Z+k3s1
```

## 7. Run the Rolling Upgrade

The playbook upgrades masters serially (one at a time), then all agent servers:

```bash
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags upgrade
```

The `k3s_upgrade` role (from `k3s-io/k3s-ansible`) handles:

- Draining the node before upgrade
- Installing the new K3s binary
- Restarting the K3s service
- Waiting for the node to become Ready before moving to the next

## 8. Validate

```bash
# All nodes on new version
kubectl get nodes

# No unexpected pod restarts
kubectl get pods -A | grep -v Running | grep -v Completed

# ArgoCD healthy
argocd app list
```

## Rollback

If something goes wrong, restore from the etcd snapshot:

```bash
# Stop k3s on all masters
sudo systemctl stop k3s

# Restore snapshot (run on the node that took it — use the exact
# timestamped name from `k3s etcd-snapshot list`)
sudo k3s etcd-snapshot restore --name pre-upgrade-v1.34.x-<timestamp>

# Start k3s
sudo systemctl start k3s
```

!!! warning
    etcd snapshot restore is a destructive operation. All changes made after the snapshot was taken will be lost.
