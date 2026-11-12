data "sops_file" "booklore_oidc" {
  source_file = "../../docker/hoarder/booklore/oidc.sops.yaml"
  input_type  = "yaml"
}

locals {
  booklore_oidc = yamldecode(data.sops_file.booklore_oidc.raw)
}

# Match only independently verified existing accounts. The app must never use a
# mutable IdP username to select a local account during the first OIDC login.
resource "authentik_property_mapping_provider_scope" "booklore_profile" {
  name       = "BookLore Existing Account"
  scope_name = "profile"
  expression = <<-EOT
    import json
    accounts = json.loads(${jsonencode(jsonencode(local.booklore_oidc.verified_accounts))})
    account = accounts.get(str(request.user.pk), {})
    return {
        "booklore_username": account.get("username", ""),
        "booklore_email": account.get("email"),
        "booklore_name": account.get("name"),
    }
  EOT
}

resource "authentik_policy_expression" "booklore_existing_account" {
  name       = "BookLore Verified Existing Account"
  expression = <<-EOT
    import json
    accounts = json.loads(${jsonencode(jsonencode(local.booklore_oidc.verified_accounts))})
    account = accounts.get(str(request.user.pk), {})
    username = account.get("username")
    return (
        bool(username)
        and bool(account.get("user_id"))
        and "email" in account
        and "name" in account
        and sum(1 for candidate in accounts.values() if candidate.get("username") == username) == 1
    )
  EOT
}

resource "authentik_provider_oauth2" "booklore_oidc" {
  name                       = "BookLore OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.booklore_oidc.client_id
  client_type                = "public"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "${local.booklore_oidc.origin}/oauth2-callback"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "logout"
      url               = "${local.booklore_oidc.origin}/login"
    },
  ]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.booklore_profile.id,
  ]
}

resource "authentik_application" "booklore_oidc" {
  name               = "BookLore OIDC"
  slug               = "booklore"
  group              = "homelab"
  protocol_provider  = authentik_provider_oauth2.booklore_oidc.id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "booklore_existing_account" {
  target         = authentik_application.booklore_oidc.uuid
  policy         = authentik_policy_expression.booklore_existing_account.id
  order          = 0
  enabled        = true
  failure_result = false
}
