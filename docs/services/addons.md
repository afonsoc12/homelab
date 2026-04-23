# Addons

Cluster infrastructure components — the platform layer that everything else depends on.

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/argo-cd.png" class="svc-icon"> ArgoCD

GitOps continuous delivery controller. Watches the `master` branch and automatically syncs the cluster to match the declared state in Git.

[:octicons-book-16: Documentation](https://argo-cd.readthedocs.io/en/stable/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/addons/argocd/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/cert-manager.png" class="svc-icon"> cert-manager

Automates TLS certificate issuance and renewal via Let's Encrypt (DNS-01 challenge through Cloudflare).

[:octicons-book-16: Documentation](https://cert-manager.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/addons/cert-manager/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/metallb.png" class="svc-icon"> MetalLB

Bare-metal load balancer. Assigns external IPs to `LoadBalancer` services using L2 ARP announcements on the LAN.

[:octicons-book-16: Documentation](https://metallb.universe.tf/installation/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/addons/metallb/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/longhorn.png" class="svc-icon"> Longhorn

Distributed block storage for Kubernetes. Provides persistent volumes backed by cluster nodes, with built-in replication and snapshots.

[:octicons-book-16: Documentation](https://longhorn.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/longhorn-system/longhorn/values.sops.yaml)

---

## Reflector

Syncs Secrets and ConfigMaps across namespaces. Used to replicate TLS certificates issued in one namespace to others that need them.

[:octicons-book-16: Documentation](https://github.com/emberstack/kubernetes-reflector) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/addons/reflector/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/airflow.png" class="svc-icon"> Airflow

Workflow orchestration platform for scheduled and dependency-aware pipelines. DAGs are baked into a custom image and deployed in the `addons` namespace.

[:octicons-book-16: Documentation](https://airflow.apache.org/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/addons/airflow/values.yaml)
