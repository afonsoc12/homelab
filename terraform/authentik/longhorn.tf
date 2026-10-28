data "sops_file" "longhorn" {
  source_file = "../../kubernetes/apps/longhorn-system/longhorn/values.sops.yaml"
  input_type  = "yaml"
}

resource "authentik_provider_proxy" "longhorn" {
  name                         = "Longhorn"
  mode                         = "proxy"
  external_host                = "https://${data.sops_file.longhorn.data["ingress.host"]}"
  internal_host                = "http://longhorn-frontend.longhorn-system.svc.cluster.local"
  internal_host_ssl_validation = true
  authorization_flow           = authentik_flow.provider_authorization.uuid
  invalidation_flow            = authentik_flow.provider_logout.uuid
  skip_path_regex              = ""
  intercept_header_auth        = false
  property_mappings = [
    authentik_property_mapping_provider_scope.proxy_outpost.id,
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "longhorn" {
  name               = "Longhorn"
  slug               = "longhorn"
  protocol_provider  = authentik_provider_proxy.longhorn.id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "access_longhorn" {
  target         = authentik_application.longhorn.uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  enabled        = true
  failure_result = false
}
