# Runbook: Adding a Server

## Adding a k3s Worker

### 1. Add to Inventory

Edit `ansible/inventory/hosts.yaml` and add the new host:

```yaml
nodes:
  hosts:
    k3s-w1:   # new worker
```

### 2. Add Host Secrets

Edit the encrypted inventory secrets:

```bash
sops ansible/inventory/hosts_secrets.sops.yaml
```

Add the new host's connection details:

```yaml
k3s-w1:
  ansible_host: <tailscale-ip>
  ansible_user: <user>
  ansible_ssh_private_key_file: <path-to-key>
```

### 3. Enroll in Tailscale

If the server isn't yet on Tailscale, run provision first:

```bash
uv run ansible-playbook ansible/playbooks/provision.yml \
  --limit k3s-w1 --tags tailscale
```

### 4. Run the Cluster Playbook

```bash
uv run ansible-playbook ansible/playbooks/k3s-cluster.yml --limit k3s-w1
```

This will run prerequisites and install the k3s agent, which registers the server with the cluster automatically using the shared `token` from `k3s_cluster.sops.yml`.

### 5. Validate

```bash
kubectl get nodes
# new server should appear as Ready within ~30s
```

---

## Adding a Raspberry Pi

Same steps as above, but also add the host to the `raspberries` group:

```yaml
raspberries:
  hosts:
    rpi-new:
```

The `k3s.orchestration.raspberrypi` role (run as part of the cluster playbook) handles Pi-specific tweaks: cgroup memory configuration in `/boot/cmdline.txt`.

---

## Removing a Server

### 1. Drain and delete from Kubernetes

```bash
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <node>
```

### 2. Uninstall k3s (optional)

```bash
uv run ansible -m command -a "k3s-agent-uninstall.sh" <node> --become
```

### 3. Remove from inventory

Remove the host from `ansible/inventory/hosts.yaml` and `hosts_secrets.sops.yaml`.
