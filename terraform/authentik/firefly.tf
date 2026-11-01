data "sops_file" "firefly" {
  source_file = "../../kubernetes/apps/homelab/firefly/values.sops.yaml"
  input_type  = "yaml"
}

# A separate origin credential prevents direct clients from forging user headers.
resource "authentik_property_mapping_provider_scope" "firefly_origin" {
  name       = "Firefly proxy origin"
  scope_name = "firefly_origin"
  expression = <<-PY
    headers = {"X-Firefly-Proxy-Token": ""}
    if request.user.pk == ${tonumber(data.sops_file.secrets.data["value_078"])}:
        headers["X-Firefly-Proxy-Token"] = ${jsonencode(data.sops_file.firefly.data["secret.stringData.FIREFLY_PROXY_TOKEN"])}
    return {"ak_proxy": {"user_attributes": {"additionalHeaders": headers}}}
  PY
}

resource "authentik_provider_proxy" "firefly" {
  name                         = "Firefly Proxy"
  mode                         = "proxy"
  external_host                = "https://firefly.${local.apps_domain}"
  internal_host                = "http://firefly.homelab.svc.cluster.local:8080"
  internal_host_ssl_validation = true
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
    authentik_property_mapping_provider_scope.firefly_origin.id,
  ]
}

resource "authentik_application" "firefly" {
  name               = "Firefly III"
  slug               = "firefly"
  protocol_provider  = authentik_provider_proxy.firefly.id
  policy_engine_mode = "any"
}

moved {
  from = authentik_policy_binding.firefly_admins
  to   = authentik_policy_binding.firefly_owner
}

resource "authentik_policy_binding" "firefly_owner" {
  target         = authentik_application.firefly.uuid
  user           = tonumber(data.sops_file.secrets.data["value_078"])
  order          = 0
  failure_result = false
}

resource "authentik_outpost" "homelab" {
  name               = "Homelab Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [authentik_provider_proxy.firefly.id]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-homelab-proxy"
    kubernetes_namespace           = "homelab"
    kubernetes_replicas            = 1
    kubernetes_service_type        = "ClusterIP"
    kubernetes_disabled_components = ["ingress", "httproute", "traefik middleware", "service-metrics", "prometheus servicemonitor"]
    kubernetes_json_patches = {
      deployment = [{
        op   = "add"
        path = "/spec/template/spec/containers/0/resources"
        value = {
          requests = { cpu = "25m", memory = "64Mi" }
          limits   = { cpu = "500m", memory = "192Mi" }
        }
      }]
    }
  })
}
