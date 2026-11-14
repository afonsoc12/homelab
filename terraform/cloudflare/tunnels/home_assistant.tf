resource "cloudflare_zero_trust_access_service_token" "home_assistant" {
  account_id = var.account_id
  name       = "Home Assistant Alexa bridge"
  duration   = "8760h"
}

resource "cloudflare_zero_trust_access_policy" "home_assistant_machine" {
  account_id = var.account_id
  name       = "Home Assistant Alexa service authentication"
  decision   = "non_identity"
  include = [{ service_token = {
    token_id = cloudflare_zero_trust_access_service_token.home_assistant.id
  } }]
}

resource "cloudflare_zero_trust_access_application" "home_assistant_machine" {
  account_id                 = var.account_id
  name                       = "Home Assistant Alexa bridge"
  domain                     = "home-alexa.${var.domain}"
  type                       = "self_hosted"
  http_only_cookie_attribute = true
  policies = [{
    id         = cloudflare_zero_trust_access_policy.home_assistant_machine.id
    precedence = 1
  }]
}

resource "cloudflare_dns_record" "home_assistant_machine" {
  zone_id = var.zone_id
  name    = "home-alexa.${var.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k3s_cluster.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
