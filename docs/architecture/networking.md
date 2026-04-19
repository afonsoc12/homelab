# Networking

## Traffic Flow

External requests reach self-hosted apps through two paths:

```
Internet
    │
    ├─── Cloudflare Tunnel (cloudflared) ──► ingress-nginx ──► app
    │         └─ Zero-trust, no open ports
    │
    └─── Wireguard VPN ──► direct cluster access
              └─ For admin / trusted devices only
```

## Cloudflare

All public-facing services are routed through Cloudflare. The Terraform `cloudflare` module manages:

| Component | Description |
|-----------|-------------|
| DNS records | A/CNAME records per zone, encrypted in `dns/zone-*.sops.yaml` |
| Tunnel | Cloudflared tunnel from k3s cluster → Cloudflare edge |
| WAF / Zone settings | SSL strict mode, TLS 1.2+, bot blocking, geo-allowlist |

### Geo Allowlist

The homelab zone restricts traffic to Portugal and UK only:

```hcl
geo_block_enabled = true
geo_allowlist     = ["PT", "GB"]
```

### Zones

Two Cloudflare zones are managed:

- **homelab zone** — self-hosted services, geo-restricted, bot blocking enabled
- **personal zone** — personal site/domain, no geo restriction

## Internal Ingress (MetalLB + ingress-nginx)

[MetalLB](https://metallb.universe.tf/) provides `LoadBalancer` services on bare-metal by announcing IPs via ARP on the LAN. ingress-nginx uses a MetalLB-assigned IP as its external address.

All apps get their TLS certificates from **cert-manager** using Let's Encrypt (via Cloudflare DNS-01 challenge).

## Tailscale Mesh

Tailscale is used for:

- **Cluster inter-node communication** — especially between home nodes and the OCI master
- **Admin access** — direct `kubectl` / SSH access from trusted devices

All k3s nodes are enrolled in the Tailscale network. The `artis3n.tailscale` Ansible role manages installation and auth.

## Wireguard

A Wireguard pod runs in the `ingress` namespace for direct VPN access to the cluster network, used for devices that need full network-level access (e.g. IoT devices, internal tooling).
