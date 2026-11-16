# Authentik cannot authenticate its own Cloudflare Access gate. Provision an
# independent one-time PIN provider and require it for this application.
resource "cloudflare_zero_trust_access_identity_provider" "authentik_otp" {
  account_id = var.account_id
  name       = "Authentik Access recovery PIN"
  type       = "onetimepin"
  config     = {}
}

resource "cloudflare_zero_trust_access_policy" "authentik" {
  account_id = var.account_id
  name       = "Allow owner to Authentik"
  decision   = "allow"
  include    = [{ email = { email = var.owner_access_email } }]
  require    = [{ login_method = { id = cloudflare_zero_trust_access_identity_provider.authentik_otp.id } }]
}

resource "cloudflare_zero_trust_access_application" "authentik" {
  account_id       = var.account_id
  name             = "Authentik"
  domain           = "sso.${var.domain}"
  type             = "self_hosted"
  session_duration = "8h"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.authentik_otp.id]
  policies = [{
    id         = cloudflare_zero_trust_access_policy.authentik.id
    precedence = 1
  }]
}
