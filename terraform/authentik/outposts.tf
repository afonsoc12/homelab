# Namespace proxy outposts. Resource addresses stay unchanged when moving files.

resource "authentik_outpost" "homelab" {
  depends_on = [authentik_policy_binding.lan_admins, authentik_policy_binding.unifi_admins, authentik_policy_binding.firefly_admins]

  name               = "k8s homelab LAN Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = concat([authentik_provider_proxy.firefly.id, authentik_provider_proxy.unifi.id], [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "homelab"])
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

resource "authentik_outpost" "automation" {
  depends_on = [authentik_policy_binding.lan_admins, authentik_policy_binding.automation_admins]

  name               = "k8s automation LAN Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = concat([for provider in authentik_provider_proxy.automation : provider.id], [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "automation"])
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

resource "authentik_outpost" "lan" {
  depends_on = [authentik_policy_binding.lan_admins, authentik_policy_binding.access_uptime_kuma]

  for_each = toset(["addons", "ingress", "monitoring", "longhorn-system"])

  name               = "k8s ${each.value} LAN Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = concat([for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == each.value], each.value == "monitoring" ? [authentik_provider_proxy.uptime_kuma.id] : [])
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-${each.value}-proxy"
    kubernetes_namespace           = each.value
    kubernetes_replicas            = 1
    kubernetes_service_type        = "ClusterIP"
    kubernetes_ingress_class_name  = "contour"
    kubernetes_ingress_secret_name = each.value == "monitoring" ? "status-cert" : "local-wildcard-cert"
    kubernetes_ingress_annotations = {
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
      "projectcontour.io/response-timeout"       = "300s"
      "projectcontour.io/websocket-routes"       = "/"
    }
    kubernetes_disabled_components = concat(
      ["httproute", "traefik middleware", "service-metrics", "prometheus servicemonitor"],
      contains(["addons", "ingress"], each.value) ? ["ingress"] : []
    )
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
