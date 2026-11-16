# Authentik cannot authenticate its own Cloudflare Access gate. Use an
# independent email identity check for the public identity-provider endpoint.
resource "cloudflare_zero_trust_access_policy" "authentik" {
  account_id = var.account_id
  name       = "Allow owner to Authentik"
  decision   = "allow"
  include    = [{ email = { email = var.owner_access_email } }]
}

resource "cloudflare_zero_trust_access_application" "authentik" {
  account_id       = var.account_id
  name             = "Authentik"
  domain           = "sso.${var.domain}"
  type             = "self_hosted"
  session_duration = "8h"
  policies = [{
    id         = cloudflare_zero_trust_access_policy.authentik.id
    precedence = 1
  }]
}
