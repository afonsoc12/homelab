---
name: sops
description: Edit, create, or update SOPS-encrypted secret files in this homelab repo. Trigger when the user wants to add/change/remove a secret, credential, IP, token, or any value stored in a `.sops.yaml` file. Also use when the user asks to decrypt a file to work with it.
---

# Editing SOPS Secrets

Encryption rules: `@.sops.yaml`

## Non-encrypted fields need no decryption

Kubernetes `.sops.yaml` files use `encrypted_regex` (only `data`, `stringData`, `loadBalancerIP`, `nginx.ingress.kubernetes.io/auth-signin`) plus `mac_only_encrypted: true` — everything else in the file (e.g. `resources:`, `image:`, `replicas:`) is plaintext YAML on disk. For edits confined to those plaintext fields, just `Read`/`Edit` the `.sops.yaml` file directly like any normal file — no `sops -d`/`sops --encrypt` round-trip needed. `mac_only_encrypted` means the MAC only covers the encrypted values, so editing plaintext fields in place doesn't invalidate it.

Only fall back to decrypt/edit/re-encrypt when the change touches an actually-encrypted key.

## Direct edit (preferred)

Opens the file decrypted in $EDITOR, re-encrypts on save:

```bash
TERM=xterm sops <file>.sops.yaml
```

## Programmatic edit (e.g. adding a key)

Decrypted file lives alongside the original, prefixed `.decrypted~`, and is gitignored:

```bash
# e.g. for kubernetes/apps/values.sops.yaml
sops -d <path>/<file>.sops.yaml > <path>/.decrypted~<file>.sops.yaml
# make changes to .decrypted~<file>.sops.yaml
sops --encrypt <path>/.decrypted~<file>.sops.yaml > <path>/<file>.sops.yaml
rm <path>/.decrypted~<file>.sops.yaml
# verify
sops -d <path>/<file>.sops.yaml | grep <key>
```

Never print the decrypted content in full — grep for the specific key to verify.
