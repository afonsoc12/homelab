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

`sops --encrypt` on a fresh plaintext file only encrypts keys matched by a rule
in root `@.sops.yaml`'s `creation_rules` (matched by path) — or by whatever you
pass explicitly via `--encrypted-regex`. It does **not** know about any custom
`encrypted_regex` baked into an existing encrypted file's own metadata footer;
that footer is just a record of what was used last time, not something sops
reads back on a fresh `--encrypt`. Several files in this repo (e.g.
`kubernetes/apps/devops/forgejo/values.sops.yaml`) use a custom per-file regex
that has **no corresponding path_regex in root `.sops.yaml` at all** — for
those, the generic `kubernetes/.*.y?ml` rule matches instead, which encrypts
almost nothing of what actually needs it. `--filename-override` does NOT fix
this — it only helps when the real path *does* match a root rule.

The failure mode is silent and dangerous: sops produces a file with a
perfectly valid envelope (real MAC, real PGP block), `sops -d` decrypts it
without complaint, and the fields that were supposed to be encrypted are just
sitting in **plaintext**. This has caused a real credential leak — always
follow the steps below.

**Before touching the file**, capture its existing `encrypted_regex` (read the
tail of the file, or `sops -d <file> 2>&1 | tail` shows the effective config on
some sops versions — safest is to just `Read` the committed file's `sops:`
footer, which is plaintext):

```bash
grep -A1 encrypted_regex <file>.sops.yaml
```

Then **always pass that exact `--encrypted-regex` explicitly** on the encrypt
step — never rely on path-based rule matching for a round-trip:

```bash
F=<path>/<file>.sops.yaml
DEC=<path>/.decrypted~<file>.sops.yaml
sops -d "$F" > "$DEC"
# make changes to $DEC
sops --encrypt --encrypted-regex '<the regex captured above>' \
     --pgp 47E4999BED565F9874AA0E7C05DA03D000FC10D1 --mac-only-encrypted "$DEC" > "$F"
rm "$DEC"
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

If any key shows `total != encrypted`, the file is broken — do not commit it. Re-run the encrypt step with the correct `--encrypted-regex` and verify again.
