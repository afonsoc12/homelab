resource "authentik_provider_oauth2" "cloudflare_access" {
  name                       = "Cloudflare Access OIDC"
  authentication_flow        = authentik_flow.login.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = "cloudflare-access"
  client_secret              = data.sops_file.secrets.data["cloudflare_access.client_secret"]
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "hours=1"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = "https://${data.sops_file.secrets.data["cloudflare_access.team_domain"]}/cdn-cgi/access/callback"
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "cloudflare_access" {
  name               = "Cloudflare Access"
  slug               = "cloudflare-access"
  protocol_provider  = authentik_provider_oauth2.cloudflare_access.id
  policy_engine_mode = "any"
}

resource "authentik_policy_binding" "cloudflare_access_admins" {
  target         = authentik_application.cloudflare_access.uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  failure_result = false
}
