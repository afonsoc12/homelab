resource "authentik_provider_proxy" "unifi" {
  name                         = "UniFi Proxy"
  mode                         = "proxy"
  external_host                = "https://unifi.local.${local.apps_domain}"
  internal_host                = "https://${data.sops_file.kubernetes.data["upstream_tls.unifi.server_name"]}"
  internal_host_ssl_validation = true
  intercept_header_auth        = false
  authentication_flow          = authentik_flow.login.uuid
  authorization_flow           = authentik_flow.provider_consent.uuid
  invalidation_flow            = authentik_flow.provider_logout.uuid
  access_token_validity        = "hours=1"
  refresh_token_validity       = "hours=8"
  property_mappings = [
    authentik_property_mapping_provider_scope.proxy_outpost.id,
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
    authentik_property_mapping_provider_scope.oidc_entitlements.id,
  ]
}

resource "authentik_application" "unifi" {
  name               = "UniFi"
  meta_icon          = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unifi.png"
  slug               = "unifi"
  group              = "homelab"
  protocol_provider  = authentik_provider_proxy.unifi.id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "unifi_admins" {
  target         = authentik_application.unifi.uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  failure_result = false
}
