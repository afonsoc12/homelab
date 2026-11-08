resource "authentik_certificate_key_pair" "signing" {
  certificate_data = data.sops_file.secrets.data["value_077"]
  key_data         = data.sops_file.secrets.data["value_005"]
  name             = "Homelab - Signing"
}

resource "authentik_outpost" "embedded" {
  depends_on = [authentik_policy_binding.lan_admins]

  # The Helm chart owns the Ingress, including the embedded-outpost path.
  config = jsonencode(merge(jsondecode(data.sops_file.secrets.data["value_009"]), {
    kubernetes_disabled_components = ["ingress", "httproute"]
  }))
  name               = "authentik Embedded Outpost"
  protocol_providers = [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == "ingress"]
  service_connection = authentik_service_connection_kubernetes.cluster.id
  type               = "proxy"
}

resource "authentik_service_connection_kubernetes" "cluster" {
  kubeconfig = "{}"
  local      = true
  name       = "Homelab - Cluster"
  verify_ssl = true
}
