---
name: terraform
description: Plan or apply changes in this repo's terraform/ modules (adguard, backblaze, cloudflare, mariadb, oci, postgres). Trigger when the user wants to add a service database/user, change DNS/tunnels, provision cloud resources, or otherwise run terraform init/plan/apply in this homelab repo.
---

# Working with Terraform Modules

Modules live under `terraform/<module>/` (`adguard`, `backblaze`, `cloudflare`, `mariadb`, `oci`, `postgres`). Full overview: `@docs/terraform/overview.md`.

## Backend init (required once per working copy/worktree)

State is remote (S3-compatible, Backblaze B2). The backend config is SOPS-encrypted at `terraform/backend.sops.tfbackend`:

```bash
cd terraform/<module>
sops -d ../backend.sops.tfbackend > ../.decrypted~backend.sops.tfbackend
terraform init -backend-config=../.decrypted~backend.sops.tfbackend -input=false
rm ../.decrypted~backend.sops.tfbackend   # after init completes; gitignored either way
```

Re-run `init` if you switch worktrees/clones — the `.terraform/` dir isn't shared.

## Plan / apply

```bash
terraform plan -out=change.tfplan
# review the plan output — resource count and names should match intent
terraform apply "change.tfplan"
rm change.tfplan
```

Never `apply` without reviewing a saved plan first. These commands touch real, shared infrastructure (DNS, DBs, cloud compute) — treat `apply` as a consequential action.

## Adding a service database (mariadb / postgres)

Both modules follow the same pattern in `service_databases.tf`: append the new name to the `local.service_databases` set. A role, database, random password, and grant are created automatically via `for_each`.

```hcl
service_databases = toset([
  "existing_app",
  "new_app",   # add here
])
```

After `apply`, retrieve the generated password from the sensitive output — don't print it to chat/logs, pipe straight into the consumer (e.g. a `sops`-encrypted k8s values file):

```bash
terraform output -json user_passwords | python3 -c "import json,sys; print(json.load(sys.stdin)['new_app'])"
```

Postgres app connection strings use the in-cluster service host `postgres.databases:5432` (or `mariadb.databases:3306`), NOT the external host in `secrets.sops.yaml` — that host is only for the terraform provider itself. URL-encode the password if it's embedded in a connection string (special chars).

## Cleanup

`.tfplan` files and `.decrypted~*` are gitignored — remove them after use but no harm leaving them locally.
