# Secrets Management (SOPS)

All secrets in this repo are encrypted with [SOPS](https://github.com/getsops/sops) and committed as ciphertext. **No plaintext secrets are ever committed.**

## Encryption Key

Encryption is done with a **PGP key**:

```
47E4999BED565F9874AA0E7C05DA03D000FC10D1
```

The PGP private key must be available in your local keyring to encrypt/decrypt. SOPS resolves it automatically via GPG.

!!! tip "Migrating to age"
    Migrating from PGP to [age](https://github.com/FiloSottile/age) is on the roadmap. `age` keys are simpler to manage (no keyring required — just a file) and are the modern standard for SOPS.

## Encryption Rules (`.sops.yaml`)

The `.sops.yaml` at the repo root defines which fields are encrypted per file path:

| Path regex | Encrypted fields |
|------------|-----------------|
| `kubernetes/.*.y?ml` | `data`, `stringData`, `loadBalancerIP`, `nginx.ingress.kubernetes.io/auth-signin` |
| `ansible/inventory/(group\|host)_vars/.*\.sops\.ya?ml` | `token`, `api_endpoint`, `tailscale_authkey`, `ansible_host`, `ansible_user`, `ansible_ssh_private_key_file` |
| `terraform/cloudflare/dns/.*\.sops\.yaml` | `name`, `content` (DNS record names and IPs) |
| Everything else | Full file encryption (fallback rule) |

Using `encrypted_regex` means only sensitive fields are encrypted — the rest of the file is readable YAML, which keeps diffs clean and reviewable.

`mac_only_encrypted: true` ensures the SOPS MAC covers only the encrypted values, not the full file.

## Patterns by Tool

=== "Kubernetes"

    ArgoCD apps reference `values.sops.yaml` alongside `values.yaml`. ArgoCD decrypts on the fly using the cluster's SOPS key (injected as a Kubernetes secret during bootstrap).

    ```
    kubernetes/apps/<namespace>/<app>/
    ├── values.yaml          # plain values — readable
    └── values.sops.yaml     # encrypted — only sensitive keys are ciphertext
    ```

    Edit a Kubernetes secret file:
    ```bash
    sops kubernetes/apps/homelab/myapp/values.sops.yaml
    ```

=== "Ansible"

    The `community.sops.sops` vars plugin decrypts inventory secrets automatically at runtime. No manual decryption step needed.

    ```
    ansible/inventory/
    ├── hosts_secrets.sops.yaml          # host IPs, SSH keys
    └── group_vars/k3s_cluster.sops.yml  # cluster token, k3s version
    ```

    Edit:
    ```bash
    sops ansible/inventory/hosts_secrets.sops.yaml
    ```

=== "Terraform"

    The `carlpett/sops` Terraform provider reads `.sops.yaml` files as data sources and exposes their values as Terraform locals.

    ```hcl
    data "sops_file" "secrets" {
      source_file = "secrets.sops.yaml"
      input_type  = "yaml"
    }

    provider "cloudflare" {
      api_token = data.sops_file.secrets.data["api_token"]
    }
    ```

## Common Operations

```bash
# Edit an encrypted file (opens $EDITOR with decrypted content)
sops <file>.sops.yaml

# Encrypt a new file
sops --encrypt --in-place <file>.sops.yaml

# Decrypt to stdout (for inspection)
sops -d <file>.sops.yaml

# Rotate keys (re-encrypt with new key)
sops rotate -i <file>.sops.yaml
```

## Pre-commit Hook (gitleaks)

[gitleaks](https://github.com/gitleaks/gitleaks) runs as a pre-commit hook and blocks any commit that contains secrets (API keys, tokens, private keys, etc.). This acts as a last-resort safety net.

```bash
# Install pre-commit hooks
pre-commit install

# Run manually
pre-commit run gitleaks --all-files
```
