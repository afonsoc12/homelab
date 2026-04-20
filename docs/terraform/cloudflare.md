# Cloudflare Module

Manages Cloudflare DNS, tunnels, and zone-level security settings.

```
terraform/cloudflare/
├── terraform.tf       # Provider config + S3 backend
├── main.tf            # Module composition
├── dns/               # DNS records (per zone)
├── tunnels/           # Cloudflare Tunnel config
└── zone/              # Zone-level settings (SSL, WAF, geo)
```

## `dns` — DNS Records

Manages A/CNAME/MX/TXT records per zone. Records are stored in SOPS-encrypted YAML files (`zone-homelab.sops.yaml`, `zone-personal.sops.yaml`) so hostnames and IPs are not exposed in plaintext.

## `zone` — Zone Settings

Applies per-zone security and performance settings:

```hcl
module "zone_homelab" {
  ssl_mode         = "strict"
  min_tls_version  = "1.2"
  always_use_https = true
  block_bots        = true
  geo_block_enabled = true
  geo_allowlist     = ["PT", "GB"]   # Portugal + UK only
}
```

## `tunnels` — Cloudflare Tunnel

Creates and configures the Cloudflared tunnel that connects the k3s cluster to the Cloudflare edge. The tunnel secret is read from SOPS.
