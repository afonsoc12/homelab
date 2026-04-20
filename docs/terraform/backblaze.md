# Backblaze Module

Manages B2 buckets and scoped application keys. Bucket names are SOPS-encrypted; lifecycle config flags (`encryption`, `file_lock`) are plaintext in `secrets.sops.yaml`.

```
terraform/backblaze/
├── terraform.tf       # Provider config + S3 backend
├── main.tf            # Buckets + application keys
└── buckets/           # Reusable bucket submodule
```

## Buckets

| Bucket | Encryption | Object Lock | Used by |
|--------|-----------|-------------|---------|
| `longhorn` | Disabled | No | Longhorn backups |
| `terraform` | SSE-B2 | Yes | Terraform state backend |
| `velero` | Disabled | No | Velero cluster backups |

## Application Keys

Scoped application keys (`longhorn`, `velero`) are managed as Terraform resources. To rotate:

```bash
terraform apply -replace=b2_application_key.longhorn -replace=b2_application_key.velero
terraform output -raw longhorn_application_key
terraform output -raw velero_application_key

```
