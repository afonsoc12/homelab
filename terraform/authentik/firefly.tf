resource "authentik_provider_proxy" "firefly" {
  name                         = "Firefly Proxy"
  mode                         = "proxy"
  external_host                = "https://firefly.${local.apps_domain}"
  internal_host                = "http://firefly.homelab.svc.cluster.local:8080"
  internal_host_ssl_validation = true
  authentication_flow          = authentik_flow.login_choice.uuid
  depends_on                   = [authentik_flow_stage_binding.login_choice]
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

resource "authentik_application" "firefly" {
  group              = "homelab"
  meta_icon          = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/firefly-iii.png"
  name               = "Firefly III"
  slug               = "firefly"
  protocol_provider  = authentik_provider_proxy.firefly.id
  policy_engine_mode = "any"
}

resource "authentik_policy_binding" "firefly_admins" {
  target         = authentik_application.firefly.uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  failure_result = false
}

# Restore the original binding address after retiring header-based login.
moved {
  from = authentik_policy_binding.firefly_owner
  to   = authentik_policy_binding.firefly_admins
}

resource "authentik_policy_binding" "firefly_shared_user" {
  target         = authentik_application.firefly.uuid
  user           = tonumber(data.sops_file.secrets.data["firefly.additional_user_id"])
  order          = 1
  failure_result = false
}
