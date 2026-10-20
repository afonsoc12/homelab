resource "authentik_property_mapping_provider_scope" "oidc_entitlements" {
  description = "Application entitlements"
  expression  = data.sops_file.secrets.data["value_030"]
  name        = "Homelab - OIDC Entitlements"
  scope_name  = "entitlements"
}

resource "authentik_property_mapping_provider_scope" "oidc_email" {
  description = "Email address"
  expression  = data.sops_file.secrets.data["value_033"]
  name        = "Homelab - OIDC Email"
  scope_name  = "email"
}

resource "authentik_property_mapping_provider_scope" "oidc_openid" {
  description = ""
  expression  = "# This scope is required by the OpenID-spec, and must as such exist in authentik.\n# The scope by itself does not grant any information\nreturn {}"
  name        = "Homelab - OIDC Openid"
  scope_name  = "openid"
}

resource "authentik_property_mapping_provider_scope" "oidc_profile" {
  description = "General Profile Information"
  expression  = data.sops_file.secrets.data["value_034"]
  name        = "Homelab - OIDC Profile"
  scope_name  = "profile"
}

resource "authentik_property_mapping_provider_scope" "proxy_outpost" {
  description = "authentik Proxy - User information"
  expression  = data.sops_file.secrets.data["value_035"]
  name        = "Homelab - Proxy Outpost"
  scope_name  = "ak_proxy"
}

resource "authentik_property_mapping_provider_scope" "mealie_email_verified" {
  description = ""
  expression  = data.sops_file.secrets.data["value_036"]
  name        = "Homelab - Mealie Email Verified"
  scope_name  = "email"
}
