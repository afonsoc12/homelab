data "sops_file" "paperless_oidc" {
  source_file = "../../kubernetes/apps/homelab/paperless/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  paperless_values = yamldecode(data.sops_file.paperless_oidc.raw)
  paperless_oidc   = jsondecode(local.paperless_values.secret.stringData.PAPERLESS_SOCIALACCOUNT_PROVIDERS).openid_connect.APPS[0]
}

resource "authentik_provider_oauth2" "paperless_oidc" {
  name                       = "Paperless OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.paperless_oidc.client_id
  client_secret              = local.paperless_oidc.secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = "https://paperless.local.${local.apps_domain}/accounts/oidc/${local.paperless_oidc.provider_id}/login/callback/"
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

resource "authentik_application" "paperless_oidc" {
  name               = "Paperless OIDC"
  slug               = "paperless"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.paperless_oidc.id
  policy_engine_mode = "all"
}

# Start with no members. Add users after verifying their existing Paperless
# accounts and rehearse the link while the original proxy and local login work.
resource "authentik_group" "paperless_oidc" {
  name         = "paperless-oidc"
  is_superuser = false
  parents      = []
  roles        = []

  lifecycle {
    ignore_changes = [users]
  }
}

resource "authentik_policy_binding" "paperless_oidc" {
  target         = authentik_application.paperless_oidc.uuid
  group          = authentik_group.paperless_oidc.id
  order          = 0
  enabled        = true
  failure_result = false
}
