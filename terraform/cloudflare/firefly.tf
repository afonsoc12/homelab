data "sops_file" "authentik" {
  source_file = "../authentik/secrets.sops.yaml"
  input_type  = "yaml"
}

resource "cloudflare_zero_trust_access_identity_provider" "authentik" {
  account_id = data.sops_file.secrets.data["account_id"]
  name       = "Authentik"
  type       = "oidc"
  config = {
    client_id        = "cloudflare-access"
    client_secret    = data.sops_file.authentik.data["cloudflare_access.client_secret"]
    auth_url         = "${trimsuffix(data.sops_file.authentik.data["url"], "/")}/application/o/authorize/"
    token_url        = "${trimsuffix(data.sops_file.authentik.data["url"], "/")}/application/o/token/"
    certs_url        = "${trimsuffix(data.sops_file.authentik.data["url"], "/")}/application/o/cloudflare-access/jwks/"
    scopes           = ["openid", "email", "profile"]
    email_claim_name = "email"
    pkce_enabled     = true
  }
}
