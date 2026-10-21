# Terraform Overview

Terraform manages Authentik identity configuration, Cloudflare DNS/tunnels, Oracle Cloud compute, Backblaze B2 storage, AdGuard Home configuration, and database user/grant management.

## Modules

```
terraform/
├── authentik/     # Identity configuration, flows, providers, policies, and branding
├── adguard/       # AdGuard Home DNS rewrites, filters, and config
├── cloudflare/    # DNS records, tunnels, WAF, zone settings
├── mariadb/       # MariaDB databases, users, and grants
├── oci/           # Oracle Cloud instance (k3s-oci-m3) and networking
├── postgres/      # PostgreSQL databases, users, and grants
└── backblaze/     # B2 buckets and scoped application keys
```

### `authentik`

Manages static Authentik configuration using `goauthentik/authentik` (`~> 2026.0`).
Existing object IDs, OAuth client credentials, signing material, MFA setup flows,
account lifecycle flows, access policies, and memberships are retained.

| File | Purpose |
|------|---------|
| `applications.tf`, `mappings.tf` | OAuth2 providers, Uptime Kuma proxy, applications, and claims |
| `flows.tf`, `stages.tf`, `policies.tf`, `policy_bindings.tf` | Login, MFA, account lifecycle, and authorization |
| `notifications.tf`, `system.tf` | Event rules, certificate, and outpost |
| `blueprints.tf` | Disable packaged reconciliation except system user attributes |
| `brand.tf` | Homelab title and login CSS |
| `secrets.sops.yaml` | Encrypted provider credentials, access-binding IDs, and private configuration with opaque keys |

Terraform owns static administrative settings. Authentik owns groups, group
memberships, user accounts, their metadata, passwords, MFA devices,
sessions, tokens, OAuth grants, event history, its built-in source, generated
outpost accounts/permissions, and packaged system attribute definitions. User and group
resources were forgotten from Terraform state without deleting accounts or groups
or changing memberships. Existing user- and group-specific access bindings reference
encrypted IDs.
Tenant-level configuration is outside this module's ownership.

Use `terraform plan -parallelism=1 -out=change.tfplan` and review the saved plan
before applying. Keep plans, state snapshots, and API inventories outside Git;
they can contain credentials. Existing objects were imported directly into remote
state, and their Terraform addresses were renamed there. The module contains no
import blocks or one-time state-repair declarations.

The cleanup removes unused protocol mappings, obsolete setup/source configuration,
an unused email stage and test application, unreferenced groups, and the unused
Grafana OAuth integration. Retained flows, stages, policies, and mappings use
Homelab names; flow slugs use the `homelab-` prefix. Packaged blueprint controls
remain disabled, except the user-attribute schema, so
removed configuration is not recreated. The embedded outpost retains its
API-enforced system name.

Authelia and LLDAP remain required until their remaining consumers migrate.
ArgoCD, Mealie, Node-RED, and Uptime Kuma integrations remain. Node-RED uses its
existing OpenID strategy in persistent settings; its consumer configuration still
needs reconciliation with Git. Grafana has no configured OAuth consumer, so its
unused Authentik application/provider are removed.

### `adguard`

Manages AdGuard Home running on `rpi-4b` via the [`gmichels/adguard`](https://registry.terraform.io/providers/gmichels/adguard/latest) provider.

| File | Purpose |
|------|---------|
| `config.tf` | Global AdGuard settings (DNS, filtering, stats, query log) |
| `dns_rewrites.tf` | Local DNS rewrites (LAN IPs + OCI public IP for Plex) |
| `filters_deny.tf` | Blocklists |
| `filters_allow.tf` | Allowlists |
| `user_rules.tf` | Custom user rules |
| `secrets.sops.yaml` | Encrypted: host, username, password, domain, OCI public IP |

!!! note "Known provider bug"
    `gmichels/adguard` v1.7.0 returns unknown values for `tls.*` fields after apply, which taints `adguard_config`. A `lifecycle { ignore_changes = [tls] }` workaround is in place. If the resource becomes tainted, run `terraform untaint adguard_config.main` before applying.

### `mariadb`

Manages MariaDB databases, users, and grants via the [`petoju/mysql`](https://registry.terraform.io/providers/petoju/mysql/latest) provider.

| File | Purpose |
|------|---------|
| `service_databases.tf` | Service databases, users, and grants — add names to `local.service_databases` |
| `mysqld_exporter_user.tf` | Monitoring user (`mysqld_exporter`) with `PROCESS`, `REPLICATION CLIENT`, `SELECT` |
| `providers.tf` | MySQL provider config (reads from SOPS) |
| `secrets.sops.yaml` | Encrypted: endpoint, terraform credentials, per-user passwords |

Add a new database by appending its name to `local.service_databases` in `service_databases.tf`.

### `postgres`

Manages PostgreSQL databases, roles, and grants via the [`cyrilgdn/postgresql`](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest) provider.

| File | Purpose |
|------|---------|
| `service_databases.tf` | Service roles, databases, and grants — add names to `local.service_databases` |
| `read_only_users.tf` | Read-only roles (e.g. `grafana`) granted `pg_read_all_data` |
| `providers.tf` | PostgreSQL provider config (reads host:port and credentials from SOPS) |
| `secrets.sops.yaml` | Encrypted: host:port, terraform credentials, per-user passwords |

Add a new service database by appending its name to `local.service_databases` in `service_databases.tf`. Read-only accounts go in `read_only_users.tf`.

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
| `goauthentik/authentik` | `~> 2026.0` | Identity configuration, flows, providers, and policies |
| `gmichels/adguard` | `~> 1.7` | AdGuard Home configuration |
| `cloudflare/cloudflare` | `~> 5.0` | Cloudflare resources |
| `oracle/oci` | `8.10.0` | Oracle Cloud Infrastructure resources |
| `Backblaze/b2` | `~> 0.12.1` | Backblaze B2 buckets and application keys |
| `petoju/mysql` | `~> 3.0` | MariaDB databases, users, and grants |
| `cyrilgdn/postgresql` | `~> 1.25` | PostgreSQL databases, roles, and grants |
| `hashicorp/random` | `~> 3.0` | Random password generation |

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
