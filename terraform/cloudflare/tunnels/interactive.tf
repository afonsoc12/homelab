# These browser-facing hosts require both an explicitly allowed identity and
# the Authentik login method. Machine clients must authenticate to Access too.
locals {
  interactive_apps = {
    home     = "Home Assistant"
    seerr    = "Seerr"
    calibre  = "Calibre-Web"
    rss      = "FreshRSS"
    status   = "Uptime Kuma"
    wallabag = "Wallabag"
  }
}

resource "cloudflare_zero_trust_access_policy" "interactive" {
  account_id       = var.account_id
  name             = "Allow owner through Authentik"
  decision         = "allow"
  session_duration = "8h"
  include          = [{ email = { email = var.owner_access_email } }]
  require          = [{ login_method = { id = var.authentik_idp_id } }]
}

resource "cloudflare_zero_trust_access_application" "interactive" {
  for_each                   = local.interactive_apps
  account_id                 = var.account_id
  name                       = each.value
  domain                     = "${each.key}.${var.domain}"
  type                       = "self_hosted"
  session_duration           = "8h"
  allowed_idps               = [var.authentik_idp_id]
  http_only_cookie_attribute = true
  policies = [{
    id         = cloudflare_zero_trust_access_policy.interactive.id
    precedence = 1
  }]
}
