locals {
  freshrss_oidc = jsondecode(data.sops_file.secrets.data["freshrss.oidc"])
  freshrss_accounts = {
    for account in local.freshrss_oidc.verified_accounts :
    tostring(account.user_id) => { username = account.username }
  }
}

# FreshRSS usernames identify existing user directories and their databases.
# Do not select them from mutable profile fields or create users during login.
resource "authentik_property_mapping_provider_scope" "freshrss_username" {
  name       = "FreshRSS Existing Username"
  scope_name = "profile"
  expression = <<-EOT
    import json
    accounts = json.loads(${jsonencode(jsonencode(local.freshrss_accounts))})
    return {"freshrss_username": accounts.get(str(request.user.pk), {}).get("username", "")}
  EOT
}

resource "authentik_policy_expression" "freshrss_existing_account" {
  name       = "FreshRSS Verified Existing Account"
  expression = <<-EOT
    import json
    accounts = json.loads(${jsonencode(jsonencode(local.freshrss_accounts))})
    username = accounts.get(str(request.user.pk), {}).get("username")
    return bool(username) and sum(1 for account in accounts.values() if account.get("username") == username) == 1
  EOT
}

resource "authentik_provider_oauth2" "freshrss_oidc" {
  name                       = "FreshRSS OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.freshrss_oidc.client_id
  client_secret              = local.freshrss_oidc.client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = local.freshrss_oidc.redirect_url
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.freshrss_username.id,
  ]
}

resource "authentik_application" "freshrss_oidc" {
  name               = "FreshRSS OIDC"
  slug               = "freshrss"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.freshrss_oidc.id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "freshrss_existing_account" {
  target         = authentik_application.freshrss_oidc.uuid
  policy         = authentik_policy_expression.freshrss_existing_account.id
  order          = 0
  enabled        = true
  failure_result = false
}
