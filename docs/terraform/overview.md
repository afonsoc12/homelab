# Terraform Overview

Terraform manages infrastructure outside the Kubernetes cluster: Cloudflare DNS/tunnels, Oracle Cloud compute, and Backblaze B2 storage.

## Modules

```
terraform/
├── cloudflare/    # DNS records, tunnels, WAF, zone settings
├── oci/           # Oracle Cloud instance (k3s-oci-m3) and networking
└── backblaze/     # B2 buckets and scoped application keys
```

## Backend

State is stored in an S3-compatible backend (Backblaze B2, `terraform` bucket). The backend config is SOPS-encrypted:

```bash
# backend.sops.tfbackend contains bucket, endpoint, access_key, secret_key
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend
terraform init -backend-config=../.decrypted~backend.sops.tfbackend
```

!!! info "Decrypted intermediary"
    The `.decrypted~backend.sops.tfbackend` file is a temporary plaintext copy. It is gitignored (`.decrypted~*` pattern) and must never be committed.

## Providers

| Provider | Version | Purpose |
|----------|---------|---------|
| `carlpett/sops` | `~> 1.1` | Read SOPS-encrypted files as Terraform data sources |
| `cloudflare/cloudflare` | `~> 5.0` | Cloudflare resources |
| `oracle/oci` | `8.10.0` | Oracle Cloud Infrastructure resources |
| `Backblaze/b2` | `~> 0.12.1` | Backblaze B2 buckets and application keys |

## Running Terraform

```bash
cd terraform/<module>

# Decrypt backend config (required once per session)
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend

# Init, plan, apply
terraform init -backend-config=../.decrypted~backend.sops.tfbackend
terraform plan
terraform apply

# Clean up
rm ../.decrypted~backend.sops.tfbackend
```

!!! warning "Never commit `.decrypted~*` files"
    These files contain plaintext secrets. They are gitignored by default, but double-check before committing.
