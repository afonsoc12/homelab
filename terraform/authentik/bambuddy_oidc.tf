data "sops_file" "bambuddy_oidc" {
  source_file = "../../kubernetes/apps/homelab/bambuddy/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  bambuddy_values = yamldecode(data.sops_file.bambuddy_oidc.raw)
  bambuddy_oidc   = local.bambuddy_values.secret.stringData
}

resource "authentik_provider_oauth2" "bambuddy_oidc" {
  name                       = "Bambuddy OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.bambuddy_oidc.BAMBUDDY_OIDC_CLIENT_ID
  client_secret              = local.bambuddy_oidc.BAMBUDDY_OIDC_CLIENT_SECRET
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = "https://bambu.local.${local.apps_domain}/api/v1/auth/oidc/callback"
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
    authentik_property_mapping_provider_scope.native_oidc_email.id,
  ]
}

resource "authentik_application" "bambuddy_oidc" {
  name               = "Bambuddy OIDC"
  slug               = "bambuddy"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.bambuddy_oidc.id
  policy_engine_mode = "all"
}

# Enrollment follows the account bootstrap and verified-identity rehearsal.
resource "authentik_group" "bambuddy_oidc" {
  name         = "bambuddy-oidc"
  is_superuser = false
  parents      = []
  roles        = []

  users = local.homelab_user_mappings.members.bambuddy
}

resource "authentik_policy_binding" "bambuddy_oidc" {
  target         = authentik_application.bambuddy_oidc.uuid
  group          = authentik_group.bambuddy_oidc.id
  order          = 0
  enabled        = true
  failure_result = false
}

resource "authentik_policy_binding" "bambuddy_verified_email" {
  target         = authentik_application.bambuddy_oidc.uuid
  policy         = authentik_policy_expression.native_oidc_verified_email.id
  order          = 1
  enabled        = true
  failure_result = false
}
