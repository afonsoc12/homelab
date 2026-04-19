# Architecture Overview

## High-Level Design

```
                    ┌─────────────────────────────────────────┐
                    │              GitHub (this repo)          │
                    │            master branch = truth         │
                    └────────────────┬────────────────────────┘
                                     │ push
                                     ▼
  ┌──────────────────────────────────────────────────────────────────┐
  │                        k3s Cluster                               │
  │                                                                  │
  │   ┌──────────┐   ┌──────────┐   ┌──────────────────────────┐   │
  │   │  k3s-m1  │   │  k3s-m2  │   │  k3s-oci-m3 (OCI)        │   │
  │   │  master  │   │  master  │   │  master (Tailscale VPN)   │   │
  │   └──────────┘   └──────────┘   └──────────────────────────┘   │
  │                                                                  │
  │   ┌──────────┐   ┌──────────┐                                   │
  │   │  rpi-4b  │   │  hoarder │  (NAS — storage only)             │
  │   │  worker  │   │  Unraid  │                                   │
  │   └──────────┘   └──────────┘                                   │
  │                                                                  │
  │   ArgoCD watches GitHub → applies changes automatically          │
  └──────────────────────────────────────────────────────────────────┘
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
  ┌──────────────┐    ┌────────────────┐
  │  Cloudflare  │    │ Tailscale mesh │
  │  DNS/Tunnels │    │ (node comms)   │
  └──────────────┘    └────────────────┘
```

## Repository Layout

```
homelab/
├── kubernetes/               # All Kubernetes manifests
│   ├── apps/
│   │   ├── addons/argocd-apps/    # Master chart — generates all ArgoCD Application CRDs
│   │   │   ├── application.yaml   # Bootstrap: points ArgoCD at this chart
│   │   │   ├── values.yaml        # Sets cluster destination for all apps
│   │   │   └── templates/
│   │   │       ├── <namespace>/   # One .yaml per app, one folder per namespace
│   │   │       └── ...
│   │   └── <namespace>/<app>/     # Per-app Helm values
│   │       ├── values.yaml
│   │       └── values.sops.yaml   # Encrypted secrets
│   └── charts/                    # Ad-hoc Kubernetes resource charts
├── ansible/                  # k3s provisioning and node management
│   ├── playbooks/
│   ├── roles/
│   └── inventory/
├── terraform/                # External infrastructure
│   └── cloudflare/           # DNS, tunnels, WAF
├── docs/                     # This documentation
└── .sops.yaml                # SOPS encryption rules
```

## GitOps Flow

1. A change is committed and pushed to `master`
2. ArgoCD detects drift between the cluster state and the Git state
3. ArgoCD applies the diff — creating, updating, or pruning resources
4. `selfHeal: true` ensures any manual in-cluster changes are reverted back to Git state

The **argocd-apps** chart is the root of the tree. It is itself an ArgoCD Application (defined in `application.yaml`) that generates all other Application CRDs from the `templates/` directory.

## Stack Summary

| Layer | Technology |
|-------|-----------|
| Kubernetes distribution | [k3s](https://k3s.io/) |
| GitOps | [ArgoCD](https://argoproj.github.io/cd/) |
| Ingress | [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) |
| TLS | [cert-manager](https://cert-manager.io/) + Let's Encrypt |
| Load balancer | [MetalLB](https://metallb.universe.tf/) |
| Persistent storage | [Longhorn](https://longhorn.io/) |
| Secret encryption | [SOPS](https://github.com/getsops/sops) + PGP |
| Provisioning | [Ansible](https://www.ansible.com/) |
| External infra | [Terraform](https://www.terraform.io/) |
| DNS & tunnels | [Cloudflare](https://www.cloudflare.com/) |
| VPN mesh | [Tailscale](https://tailscale.com/) |
