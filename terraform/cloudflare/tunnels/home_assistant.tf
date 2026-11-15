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

resource "cloudflare_zero_trust_access_application" "home_assistant_alexa" {
  account_id = var.account_id
  name       = "Home Assistant Alexa commands"
  domain     = "home.${var.domain}/api/alexa/smart_home"
  type       = "self_hosted"
  policies = [{
    id         = cloudflare_zero_trust_access_policy.home_assistant_machine.id
    precedence = 1
  }]
}
