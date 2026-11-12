data "sops_file" "forgejo_oidc" {
  source_file = "../../kubernetes/apps/devops/forgejo/values.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "wireguard_oidc" {
  source_file = "../../kubernetes/apps/ingress/wireguard/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  forgejo_oidc_values   = yamldecode(data.sops_file.forgejo_oidc.raw)
  wireguard_oidc_values = yamldecode(data.sops_file.wireguard_oidc.raw)
  native_oidc_apps = {
    forgejo = {
      name          = "Forgejo"
      group         = "devops"
      client_id     = local.forgejo_oidc_values.gitea.oauth[0].key
      client_secret = local.forgejo_oidc_values.gitea.oauth[0].secret
      redirect_uris = ["${trimsuffix(local.forgejo_oidc_values.gitea.config.server.ROOT_URL, "/")}/user/oauth2/authentik/callback"]
    }
    wireguard = {
      name          = "WireGuard"
      group         = "ingress"
      client_id     = local.wireguard_oidc_values.secret.stringData.OAUTH_OIDC_CLIENT_ID
      client_secret = local.wireguard_oidc_values.secret.stringData.OAUTH_OIDC_CLIENT_SECRET
      redirect_uris = [for endpoint in ["callback", "link"] : "https://wg.local.${local.apps_domain}/api/auth/oidc/${endpoint}"]
    }
  }
}

# Email verification is recorded only after the authenticated email stage sends
# a confirmation link and the user follows it. A mutable email field alone does
# not establish verification.
resource "authentik_property_mapping_provider_scope" "native_oidc_email" {
  name       = "Native OIDC Email"
  scope_name = "email"
  expression = <<-EOT
    email = request.user.email
    verified_address = request.user.attributes.get("email_verified_address")
    return {
        "email": email,
        "email_verified": bool(email) and verified_address == email,
    }
  EOT
}

resource "authentik_policy_expression" "native_oidc_verified_email" {
  name       = "Native OIDC Verified Email"
  expression = <<-EOT
    email = request.user.email
    verified_address = request.user.attributes.get("email_verified_address")
    return bool(email) and verified_address == email
  EOT
}

resource "authentik_provider_oauth2" "native_oidc" {
  # Iterate over fixed public keys; decrypted consumer values remain sensitive.
  for_each = toset(["forgejo", "wireguard"])

  name                       = "${local.native_oidc_apps[each.key].name} OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.native_oidc_apps[each.key].client_id
  client_secret              = local.native_oidc_apps[each.key].client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [for uri in local.native_oidc_apps[each.key].redirect_uris : {
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = uri
  }]
  signing_key = authentik_certificate_key_pair.signing.id
  issuer_mode = "per_provider"
  sub_mode    = "hashed_user_id"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.native_oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "native_oidc" {
  for_each = toset(["forgejo", "wireguard"])

  name               = local.native_oidc_apps[each.key].name
  slug               = each.key
  group              = local.native_oidc_apps[each.key].group
  protocol_provider  = authentik_provider_oauth2.native_oidc[each.key].id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "native_oidc_admins" {
  for_each = toset(["forgejo", "wireguard"])

  target         = authentik_application.native_oidc[each.key].uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  enabled        = true
  failure_result = false
}

resource "authentik_policy_binding" "native_oidc_verified_email" {
  # wg-easy may link accounts by email. Forgejo requires the existing local
  # account's credentials instead, with registration disabled.
  for_each = toset(["wireguard"])

  target         = authentik_application.native_oidc[each.key].uuid
  policy         = authentik_policy_expression.native_oidc_verified_email.id
  order          = 1
  enabled        = true
  failure_result = false
}
