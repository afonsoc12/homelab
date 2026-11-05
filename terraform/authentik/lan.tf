locals {
  lan_proxy_apps = {
    kopia    = { name = "Kopia", host = "kopia.local", upstream = "", validate_tls = true, mode = "forward_single" }
    glance   = { name = "Glance", host = "local", upstream = "http://glance.homelab.svc.cluster.local:8080", validate_tls = true, mode = "proxy" }
    lldap    = { name = "LLDAP", host = "ldap.local", upstream = "http://lldap.ingress.svc.cluster.local:17170", validate_tls = true, mode = "proxy" }
    unifi    = { name = "UniFi", host = "unifi.local", upstream = "https://unifi-external-external-svc.homelab.svc.cluster.local:443", validate_tls = false, mode = "proxy" }
    longhorn = { name = "Longhorn", host = "longhorn.local", upstream = "http://longhorn-frontend.longhorn-system.svc.cluster.local:80", validate_tls = true, mode = "proxy" }
  }
}

# UniFi uses its existing self-signed HTTPS backend. This retains the prior
# nginx upstream trust setting; traffic to that backend remains encrypted.
resource "authentik_provider_proxy" "lan" {
  for_each                     = local.lan_proxy_apps
  name                         = "${each.value.name} Proxy"
  mode                         = each.value.mode
  external_host                = "https://${each.value.host}.${local.apps_domain}"
  internal_host                = each.value.mode == "proxy" ? each.value.upstream : null
  internal_host_ssl_validation = each.value.validate_tls
  authentication_flow          = authentik_flow.login.uuid
  authorization_flow           = authentik_flow.provider_consent.uuid
  invalidation_flow            = authentik_flow.provider_logout.uuid
  intercept_header_auth        = false
  access_token_validity        = "hours=1"
  refresh_token_validity       = "hours=8"
  skip_path_regex              = "^/(health|healthz|ready|readyz)$\n^/api/info$\n^/api/greader\\.php$"
  property_mappings = [
    authentik_property_mapping_provider_scope.proxy_outpost.id,
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
    authentik_property_mapping_provider_scope.oidc_entitlements.id,
  ]
}

resource "authentik_application" "lan" {
  for_each           = local.lan_proxy_apps
  name               = each.value.name
  slug               = each.key
  protocol_provider  = authentik_provider_proxy.lan[each.key].id
  policy_engine_mode = "any"
}

# Preserve the legacy group's membership independently of administrator access.
resource "authentik_group" "lan_home" {
  name         = "home"
  is_superuser = false
  users        = [for id in jsondecode(data.sops_file.secrets.data["lan_home_user_ids"]) : tonumber(id)]
}

resource "authentik_policy_binding" "lan_access" {
  for_each       = local.lan_proxy_apps
  target         = authentik_application.lan[each.key].uuid
  group          = each.key == "longhorn" ? data.sops_file.secrets.data["value_079"] : authentik_group.lan_home.id
  order          = 0
  failure_result = false
}

resource "authentik_outpost" "longhorn" {
  name               = "Longhorn Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [authentik_provider_proxy.lan["longhorn"].id]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-longhorn-proxy"
    kubernetes_namespace           = "longhorn-system"
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
