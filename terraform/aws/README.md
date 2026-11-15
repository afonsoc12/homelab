# AWS

One Terraform root and one remote state.

```text
main.tf                   Providers, encrypted settings, module wiring
secrets.sops.yaml          Shared encrypted configuration
home-assistant/main.tf    Lambda, execution role, logs and permission
home-assistant/src/       Actual Lambda Python source only
alexa/main.tf             Skill manifests and account linking
alexa/credentials.sops.yaml Encrypted Alexa account credentials
iam/main.tf              Account-level IAM resources
```

Run native `terraform init`, `terraform validate`, `terraform plan`, and
`terraform apply` from this directory. Backend credentials belong in the
standard AWS environment variables, not in backend configuration files.
Review a saved plan before applying it. State and plan contents are sensitive.

Supply `TF_VAR_alexa_session` from an authorized Alexa session. It is an ephemeral
object containing `access_token` and an `etags` map keyed by `home_assistant`,
`music_assistant`, and `account_linking`, using the current GET response headers. Do not save this object to a tfvars file. Get a
fresh access token if needed, but keep the plan's ETags when applying it.
If an ETag is stale, obtain new headers and create a new plan. Alexa credentials remain outside
Terraform state; the encrypted account profile is retained for authorized client
use and is not read by Terraform.

The native REST provider masks responses and polls asynchronous manifest
updates. Updates require the matching session ETag; missing or stale ETags cause the
API to reject writes. The archive provider packages only `src/` for Lambda.
There are no custom wrappers, helper Python files, tests, import blocks or move
blocks. Dependencies are pinned exactly in Terraform and the lock file.
