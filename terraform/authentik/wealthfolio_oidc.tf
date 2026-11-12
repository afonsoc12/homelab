data "sops_file" "wealthfolio_oidc" {
  source_file = "../../kubernetes/apps/homelab/wealthfolio/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  wealthfolio_values = yamldecode(data.sops_file.wealthfolio_oidc.raw)
  wealthfolio_oidc   = local.wealthfolio_values.oidc
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
  name               = "Wealthfolio OIDC"
  slug               = "wealthfolio"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.wealthfolio_oidc.id
  policy_engine_mode = "all"
}

# Household access is explicit and remains separate from administrator groups.
resource "authentik_group" "wealthfolio_oidc" {
  name         = "wealthfolio-oidc"
  is_superuser = false
  parents      = []
  roles        = []

  users = local.homelab_user_mappings.members.wealthfolio
}

resource "authentik_policy_binding" "wealthfolio_oidc" {
  target         = authentik_application.wealthfolio_oidc.uuid
  group          = authentik_group.wealthfolio_oidc.id
  order          = 0
  enabled        = true
  failure_result = false
}
