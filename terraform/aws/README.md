# AWS Terraform

Use the runner for this module. It enforces sensitive REST response fields,
disables debug output, captures subprocess diagnostics, and supplies ephemeral
provider configuration. It supports only the existing imported resources.

Requirements: Python 3.14, Terraform 1.10 or later, Node.js, SOPS/GPG, and
`ask-cli` 2.30.7. Set `ASK_CLI_ROOT` to that installed package directory if it is
not discoverable through the installed `ask` or `ask-smapi` executable.

From this directory:

```sh
python3 tools/run.py init
python3 tools/run.py validate
python3 tools/run.py plan
python3 tools/run.py apply
```

`apply` reviews a freshly saved plan and applies that exact plan. It refuses
resource creation or deletion. Temporary plans are created with restricted
permissions and removed on completion or failure. Diagnostic output is
suppressed because upstream failures can contain private configuration.

`ask-credentials.sops.yaml` holds the ASK profile. Only the local adapter decrypts it;
Terraform never receives the Alexa access or refresh token. The official ASK CLI runs with an environment profile, without reading or
writing a plaintext CLI profile. Its pinned adapter blocks telemetry and
profile writes and captures refreshed tokens in memory. Token refreshes
remain in memory; rotated refresh tokens are saved through SOPS.

The local adapter restricts methods and paths, requires a random session token,
rejects upstream redirects, obtains ETags immediately before writes, and waits
for successful manifest builds and matching configuration before returning.
It is started only for a Terraform operation and shut down afterward. Its
endpoint and session token are ephemeral Terraform variables.

Backend credentials are passed through environment variables. `init` supplies
only noncredential backend settings through a pipe and checks the cache contains
no credentials. The runner also supports `--module cloudflare` for the adjacent module.
AWS resources and Alexa skills share this root and its remote state.

Terraform state still contains decrypted managed settings. Keep the encrypted
remote backend and its access controls protected. Historical backend versions
may retain older state data; a sensitivity marker does not encrypt state.
