data "sops_file" "apps" {
  source_file = "../../kubernetes/apps/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  apps_domain = data.sops_file.apps.data["domain"]
  protected_apps = {
    esphome     = { name = "ESPHome", host = "esphome.local", upstream = "http://esphome.automation.svc.cluster.local:6052" }
    zigbee2mqtt = { name = "Zigbee2MQTT", host = "z2m.local", upstream = "http://zigbee2mqtt.automation.svc.cluster.local:8080" }
  }
}

# Proxy mode works with ordinary, namespace-local Ingress resources.
# Each application gets an independent authorization policy.
resource "authentik_provider_proxy" "automation" {
  for_each = local.protected_apps

  name                         = "${each.value.name} Proxy"
  mode                         = "proxy"
  external_host                = "https://${each.value.host}.${local.apps_domain}"
  internal_host                = each.value.upstream
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
  ]
}

resource "authentik_application" "automation" {
  for_each = local.protected_apps

  name               = each.value.name
  slug               = each.key
  protocol_provider  = authentik_provider_proxy.automation[each.key].id
  policy_engine_mode = "any"
}

resource "authentik_policy_binding" "automation_admins" {
  for_each = local.protected_apps

  target         = authentik_application.automation[each.key].uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  failure_result = false
}

# One shared outpost in the same namespace as the protected applications.
# App charts own their Ingress resources; the outpost manages no routes.
resource "authentik_outpost" "automation" {
  name               = "Automation Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [for provider in authentik_provider_proxy.automation : provider.id]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-automation-proxy"
    kubernetes_namespace           = "automation"
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
