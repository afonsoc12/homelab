resource "authentik_provider_oauth2" "home_assistant" {
  name                       = "Home Assistant OIDC"
  authentication_flow        = authentik_flow.login.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = "home-assistant"
  client_type                = "public"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "hours=1"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = "https://home.${local.apps_domain}/auth/oidc/callback"
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "home_assistant" {
  group              = "automation"
  meta_icon          = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/home-assistant.png"
  meta_launch_url    = "https://home.${local.apps_domain}"
  name               = "Home Assistant OIDC"
  slug               = "home-assistant"
  protocol_provider  = authentik_provider_oauth2.home_assistant.id
  policy_engine_mode = "any"
}

# These are the existing Authentik accounts matched to the two remotely enabled
# Home Assistant users. New users require a separate access grant.
resource "authentik_policy_binding" "home_assistant" {
  for_each       = toset(["owner", "household"])
  target         = authentik_application.home_assistant.uuid
  user           = tonumber(data.sops_file.secrets.data["home_assistant.oidc_${each.key}_user_id"])
  order          = index(["owner", "household"], each.key)
  enabled        = true
  failure_result = false
}
