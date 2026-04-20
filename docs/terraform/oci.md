# OCI Module

Manages the Oracle Cloud free-tier ARM instance `k3s-oci-m3` (UK Cardiff region) used as a k3s master server connected via Tailscale.

```
terraform/oci/
├── terraform.tf       # Provider config + S3 backend
├── main.tf            # Module composition
├── compute/           # Boot volume + instance (k3s-oci-m3)
└── networking/        # VCN, subnet, security lists, route table
```

## `compute`

Boot volume (200 GB) + `VM.Standard.A1.Flex` instance (4 OCPUs, 24 GB RAM). Both resources have `prevent_destroy = true`.

## `networking`

VCN, subnet, internet gateway, route table, and security list with the following open ports:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| — | ICMP | Ping |
| 41641 | UDP | Tailscale |
| 32400 | TCP | Plex |
