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

# Isolate UniFi's private certificate trust from all other application proxies.
resource "authentik_outpost" "unifi" {
  depends_on = [authentik_policy_binding.unifi_admins]

  name               = "UniFi Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [authentik_provider_proxy.unifi.id]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-unifi-proxy"
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
          limits   = { cpu = "100m", memory = "128Mi" }
        }
        }, {
        op   = "add"
        path = "/spec/template/spec/hostAliases"
        value = [{
          ip        = data.sops_file.kubernetes.data["ips.unifi"]
          hostnames = [data.sops_file.kubernetes.data["upstream_tls.unifi.server_name"]]
        }]
        }, {
        op   = "add"
        path = "/spec/template/spec/volumes"
        value = [{
          name = "unifi-upstream-ca"
          secret = {
            secretName = "unifi-external-external-svc-upstream-ca"
            items = [{
              key  = "ca.crt"
              path = "${data.sops_file.kubernetes.data["upstream_tls.unifi.subject_hash"]}.0"
            }]
          }
        }]
        }, {
        op   = "add"
        path = "/spec/template/spec/containers/0/volumeMounts"
        value = [{
          name      = "unifi-upstream-ca"
          mountPath = "/etc/unifi-tls"
          readOnly  = true
        }]
        }, {
        op    = "add"
        path  = "/spec/template/spec/containers/0/env/-"
        value = { name = "SSL_CERT_FILE", value = "/etc/ssl/certs/ca-certificates.crt" }
        }, {
        op    = "add"
        path  = "/spec/template/spec/containers/0/env/-"
        value = { name = "SSL_CERT_DIR", value = "/etc/unifi-tls" }
      }]
    }
  })
}
