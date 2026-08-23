---
name: k8s-network-troubleshoot
description: Troubleshoot Kubernetes networking — DNS resolution failures, service/pod connectivity issues, NetworkPolicy blocks, or "can't reach X from inside the cluster" style problems. Trigger when a pod can't resolve a Service name, a Service isn't routing to its pods, cross-namespace traffic is blocked, or you need to test connectivity from inside the cluster network (not from this machine). Spins up a disposable debug DaemonSet, walks through DNS/connectivity checks, then tears it down.
---

# Kubernetes network troubleshooting

Uses `registry.k8s.io/e2e-test-images/agnhost` as the debug image — it's a small
Alpine-based image built specifically for this: it bundles `dig`/`nslookup`
(`bind-tools`), `curl`, `nc` (`netcat-openbsd`), `ss`/`ip` (`iproute2`), `socat`,
`iperf`, and `bash`, plus the `agnhost` CLI itself (`connect`, `netexec`,
`dns-suffix`, `dns-server-list`, ...). There's no permanent agnhost deployment
in the cluster — this skill deploys a disposable one in the `sandbox`
namespace, pinned to `:latest` since it's throwaway and short-lived by
design, and removes it when done.

## 1. Deploy the debug DaemonSet

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: net-debug
  namespace: sandbox
spec:
  selector:
    matchLabels:
      app: net-debug
  template:
    metadata:
      labels:
        app: net-debug
    spec:
      tolerations:
        - operator: Exists
      containers:
        - name: net-debug
          image: registry.k8s.io/e2e-test-images/agnhost:latest
          command: ["/agnhost", "pause"]
EOF
kubectl -n sandbox rollout status daemonset/net-debug
```

The `tolerations: [{operator: Exists}]` makes it schedule on every node, including
tainted ones (masters) — you want a debug pod reachable from every node when
diagnosing a node-specific networking issue.

Get a shell on the pod running on the node (or in the namespace) you care about:

```bash
kubectl -n sandbox get pods -o wide   # pick the pod on the node you want to test from
kubectl -n sandbox exec -it <pod> -- bash
```

## 2. DNS troubleshooting

Inside the pod (or via `kubectl exec ... -- <cmd>` directly):

```bash
# What resolver/search domains is this pod actually using?
cat /etc/resolv.conf
agnhost dns-server-list
agnhost dns-suffix

# Can it resolve a Service at all? Try the short name, the namespaced name, and
# the fully-qualified name — narrows down whether it's a search-domain issue or
# a real resolution failure.
nslookup <service-name>
nslookup <service-name>.<namespace>
nslookup <service-name>.<namespace>.svc.cluster.local
dig +short <service-name>.<namespace>.svc.cluster.local

# Is CoreDNS itself healthy and reachable?
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=100
dig @<coredns-clusterip> <service-name>.<namespace>.svc.cluster.local
```

Common causes, in rough order of likelihood:
- **`NXDOMAIN` for the short name but the FQDN works** — `search` domains in
  `/etc/resolv.conf` are missing/wrong for that namespace (check the pod's
  `dnsPolicy`/`dnsConfig` and namespace).
- **Everything times out, no answer at all** — CoreDNS pods aren't `Running`/`Ready`,
  or a NetworkPolicy is blocking egress to `kube-system` on UDP/TCP 53. Check
  `kubectl get networkpolicy -A` for anything scoping that namespace.
- **Resolves to a stale/wrong IP** — check the Service's `ClusterIP` and Endpoints
  actually match: `kubectl get svc <name> -n <namespace> -o wide` and
  `kubectl get endpoints <name> -n <namespace>` — empty Endpoints means the
  Service's `selector` doesn't match any Ready pod's labels.

## 3. Service / pod connectivity troubleshooting

```bash
# Raw TCP reachability — distinguishes DNS failure from a real network/firewall
# block. agnhost connect prefixes its error so scripts (and you) can tell them
# apart: DNS / TIMEOUT / REFUSED / OTHER.
agnhost connect --timeout=3s <service-name>.<namespace>.svc.cluster.local:<port>
agnhost connect --timeout=3s <pod-ip>:<port>

# HTTP-level check
curl -sv --max-time 5 http://<service-name>.<namespace>.svc.cluster.local:<port>/

# Raw netcat, useful for non-HTTP ports (databases, etc.)
nc -zv -w3 <host> <port>

# Socket/route-level state on the node this pod is running on
ss -tnp
ip route
```

Narrowing down where it breaks:
1. **Pod IP direct, same node** — rules out kube-proxy/Service routing entirely;
   isolates to CNI/pod network if this fails.
2. **Pod IP direct, cross-node** — isolates to the CNI's overlay/routing between
   nodes if step 1 worked but this doesn't.
3. **ClusterIP (Service DNS name)** — if pod-IP-direct works but this doesn't,
   it's kube-proxy/Service (check Endpoints are populated, as above) not the
   underlying pod network.
4. **From a pod in a different namespace than the target** — if same-namespace
   works but cross-namespace doesn't, check `NetworkPolicy` resources scoping
   either namespace (`kubectl get networkpolicy -A -o yaml`).

## 4. Clean up

Always remove the debug DaemonSet once done — it's cluster-wide and has no
resource limits set, don't leave it running:

```bash
kubectl -n sandbox delete daemonset net-debug
```
