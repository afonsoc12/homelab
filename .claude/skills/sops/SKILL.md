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

`sops --encrypt` picks its encryption rule (`path_regex` in `.sops.yaml`, and any
per-file `encrypted_regex` override already baked into that file's own metadata
footer) by matching the **input file's path** — not the output path you redirect
to. If you decrypt to a differently-named temp file (e.g. `.decrypted~foo.yaml`)
and then `sops --encrypt` *that* temp file, sops matches rules against the temp
name, silently falls back to a broader/wrong rule, and can produce a file with a
perfectly valid SOPS envelope (real MAC, real PGP block) where the fields that
were supposed to be encrypted are sitting in **plaintext**. `sops -d` will still
successfully decrypt such a file — that check alone does NOT prove encryption
was correct, only that the envelope is structurally valid.

**Always pass `--filename-override <original-path>` on both the decrypt and the
encrypt step**, so sops resolves rules against the real path regardless of the
temp file's name:

```bash
# e.g. for kubernetes/apps/devops/forgejo/values.sops.yaml
F=<path>/<file>.sops.yaml
sops --filename-override "$F" -d "$F" > <path>/.decrypted~<file>.sops.yaml
# make changes to .decrypted~<file>.sops.yaml
sops --filename-override "$F" --encrypt <path>/.decrypted~<file>.sops.yaml > "$F"
rm <path>/.decrypted~<file>.sops.yaml
```

Never print the decrypted content in full — grep for the specific key to verify a value changed, but redact/omit the value itself in any output you show.

### Mandatory post-encrypt verification

Before committing, verify **every key that's supposed to be encrypted actually is** — don't just confirm the file decrypts. Pull the file's `encrypted_regex` (or the matching root `.sops.yaml` `path_regex` rule) and check each matching key's line starts with `ENC[`, without printing the value:

```bash
# swap in the file's actual encrypted_regex key names
for k in password PASSWD DOMAIN ROOT_URL host username email; do
  total=$(grep -cE "\b${k}:" "$F")
  enc=$(grep -E "\b${k}:" "$F" | grep -c "ENC\[")
  echo "$k: total=$total encrypted=$enc"   # total must equal encrypted for every key
done
```

If any key shows `total != encrypted`, the file is broken — do not commit it. Re-run the encrypt step with `--filename-override` and verify again.
