# Runbook: K3s Upgrade

!!! warning "Never skip minor versions"
    Kubernetes version skew requires upgrading one minor version at a time (e.g. `1.33 → 1.34`, not `1.33 → 1.35`).

## 1. Find the Target Version

Find the latest patch for the target minor:

```bash
curl -s "https://api.github.com/repos/k3s-io/k3s/releases?per_page=50" \
  | jq -r '.[].tag_name' \
  | grep '^v1\.34\.' \
  | grep -v '\-rc' \
  | head -1
```

## 2. Snapshot etcd (Required for Rollback)

```bash
# Run on one of the masters
sudo k3s etcd-snapshot save --name pre-upgrade-v1.34.x
```

Verify the snapshot was created:

```bash
sudo k3s etcd-snapshot list
```

## 3. Update the Version in SOPS

```bash
sops ansible/inventory/group_vars/k3s_cluster.sops.yml
# Update: k3s_version: vX.Y.Z+k3s1
```

## 4. Run the Rolling Upgrade

The playbook upgrades masters serially (one at a time), then all agent servers:

```bash
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --tags upgrade
```

The `k3s_upgrade` role (from `k3s-io/k3s-ansible`) handles:

- Draining the node before upgrade
- Installing the new k3s binary
- Restarting the k3s service
- Waiting for the node to become Ready before moving to the next

## 5. Validate

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

# Restore snapshot (run on the node that took it)
sudo k3s etcd-snapshot restore --name pre-upgrade-v1.34.x

# Start k3s
sudo systemctl start k3s
```

!!! warning
    etcd snapshot restore is a destructive operation. All changes made after the snapshot was taken will be lost.
