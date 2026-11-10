resource "cloudflare_zero_trust_access_policy" "firefly" {
  account_id       = var.account_id
  name             = "Allow Firefly users"
  decision         = "allow"
  session_duration = "8h"
  include = [for email in var.firefly_access_emails : {
    email = { email = email }
  }]
  require = [{
    login_method = { id = var.authentik_idp_id }
  }]
}

resource "cloudflare_zero_trust_access_application" "firefly" {
  account_id                 = var.account_id
  name                       = "Firefly III"
  domain                     = "firefly.${var.domain}"
  type                       = "self_hosted"
  session_duration           = "8h"
  allowed_idps               = [var.authentik_idp_id]
  auto_redirect_to_identity  = false
  http_only_cookie_attribute = true
  policies = [{
    id         = cloudflare_zero_trust_access_policy.firefly.id
    precedence = 1
  }]
}
