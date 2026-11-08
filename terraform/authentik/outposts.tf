locals {
  outpost_disabled_components = ["httproute", "traefik middleware", "service-metrics", "prometheus servicemonitor"]
  outpost_ingress_config = {
    kubernetes_ingress_class_name  = "contour"
    kubernetes_ingress_secret_name = "local-wildcard-cert"
    kubernetes_ingress_annotations = {
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
      "projectcontour.io/response-timeout"       = "300s"
      "projectcontour.io/websocket-routes"       = "/"
    }
  }

  namespace_outposts = {
    addons = {
      providers = [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "addons"]
      config = merge(local.outpost_ingress_config, {
        kubernetes_disabled_components = concat(local.outpost_disabled_components, ["ingress"])
      })
    }
    automation = {
      providers = concat([for provider in authentik_provider_proxy.automation : provider.id], [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "automation"])
      config = {
        kubernetes_disabled_components = concat(["ingress"], local.outpost_disabled_components)
      }
    }
    homelab = {
      providers = concat([authentik_provider_proxy.firefly.id, authentik_provider_proxy.unifi.id], [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "homelab"])
      config = {
        kubernetes_disabled_components = concat(["ingress"], local.outpost_disabled_components)
      }
      # UniFi requires its private trust certificate alongside public CAs.
      deployment_patches = [{
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
    ingress = {
      providers = [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "ingress"]
      config = merge(local.outpost_ingress_config, {
        kubernetes_disabled_components = concat(local.outpost_disabled_components, ["ingress"])
      })
    }
    longhorn-system = {
      providers = [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "longhorn-system"]
      config = merge(local.outpost_ingress_config, {
        kubernetes_disabled_components = local.outpost_disabled_components
      })
    }
    monitoring = {
      providers = concat([for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "monitoring"], [authentik_provider_proxy.uptime_kuma.id])
      config = merge(local.outpost_ingress_config, {
        kubernetes_ingress_secret_name = "status-cert"
        kubernetes_disabled_components = local.outpost_disabled_components
      })
    }
  }
}

resource "authentik_outpost" "lan" {
  for_each = local.namespace_outposts
  depends_on = [
    authentik_policy_binding.lan_admins,
    authentik_policy_binding.automation_admins,
    authentik_policy_binding.firefly_admins,
    authentik_policy_binding.unifi_admins,
    authentik_policy_binding.access_uptime_kuma,
  ]

  name               = "k8s ${each.key} LAN Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = each.value.providers
  config = jsonencode(merge({
    authentik_host          = data.sops_file.secrets.data["url"]
    authentik_host_insecure = false
    container_image         = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template  = "authentik-${each.key}-proxy"
    kubernetes_namespace    = each.key
    kubernetes_replicas     = 1
    kubernetes_service_type = "ClusterIP"
    kubernetes_json_patches = {
      deployment = concat([{
        op   = "add"
        path = "/spec/template/spec/containers/0/resources"
        value = {
          requests = { cpu = "25m", memory = "64Mi" }
          limits   = { cpu = "500m", memory = "192Mi" }
        }
      }], try(each.value.deployment_patches, []))
    }
  }, each.value.config))
}

moved {
  from = authentik_outpost.homelab
  to   = authentik_outpost.lan["homelab"]
}

moved {
  from = authentik_outpost.automation
  to   = authentik_outpost.lan["automation"]
}
