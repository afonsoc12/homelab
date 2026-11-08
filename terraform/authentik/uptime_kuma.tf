resource "authentik_outpost" "uptime_kuma" {
  depends_on = [authentik_policy_binding.access_uptime_kuma]

  name               = "Uptime Kuma Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [authentik_provider_proxy.uptime_kuma.id]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-uptime-kuma-proxy"
    kubernetes_namespace           = "monitoring"
    kubernetes_replicas            = 1
    kubernetes_service_type        = "ClusterIP"
    kubernetes_ingress_class_name  = "contour"
    kubernetes_ingress_secret_name = "status-cert"
    kubernetes_ingress_annotations = {
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
      "projectcontour.io/response-timeout"       = "300s"
      "projectcontour.io/websocket-routes"       = "/"
    }
    kubernetes_disabled_components = ["httproute", "traefik middleware", "service-metrics", "prometheus servicemonitor"]
    kubernetes_json_patches = {
      deployment = [{
        op   = "add"
        path = "/spec/template/spec/containers/0/resources"
        value = {
          requests = { cpu = "25m", memory = "64Mi" }
          limits   = { cpu = "100m", memory = "128Mi" }
        }
      }]
    }
  })
}
