locals {
  wealthfolio_oidc = jsondecode(data.sops_file.secrets.data["wealthfolio.oidc"])
}

resource "authentik_provider_oauth2" "wealthfolio_oidc" {
  name                       = "Wealthfolio OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.wealthfolio_oidc.client_id
  client_secret              = local.wealthfolio_oidc.client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = local.wealthfolio_oidc.redirect_url
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "wealthfolio_oidc" {
  name               = local.dashboard_service_names.wealthfolio
  meta_icon          = local.lan_proxy_apps.wealthfolio.icon
  meta_launch_url    = "https://${local.lan_proxy_apps.wealthfolio.host}.${local.apps_domain}"
  slug               = "wealthfolio"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.wealthfolio_oidc.id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "wealthfolio_oidc" {
  target         = authentik_application.wealthfolio_oidc.uuid
  policy         = authentik_policy_expression.group_access.id
  order          = 0
  enabled        = true
  failure_result = false
}
