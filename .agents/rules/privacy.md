# Privacy — No Sensitive Data in Plaintext

NEVER include in any file, doc, commit message, or response:

- External IP addresses
- LAN IP addresses
- Tailscale IP addresses
- Full domains (e.g. `domain.tld`) — subdomains are fine (e.g. `adguard.local.{{ .Values.domain }}`)
- Credentials, tokens, API keys, passwords

All of the above belong in SOPS-encrypted files only. Use template variables (`{{ .Values.domain }}`, `${data.sops_file.secrets.data["domain"]}`) everywhere else.

Sops encrypted files always end in `*.sops.ext` (e.g.  `secrets.sops.yaml`). Decrypting them to work with their contents is fine — exposing the decrypted content in docs, commit messages, or any plaintext file is NOT ALLOWED.
