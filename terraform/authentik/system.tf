resource "authentik_certificate_key_pair" "signing" {
  certificate_data = data.sops_file.secrets.data["value_077"]
  key_data         = data.sops_file.secrets.data["value_005"]
  name             = "Homelab - Signing"
}

resource "authentik_outpost" "embedded" {
  config             = data.sops_file.secrets.data["value_009"]
  name               = "authentik Embedded Outpost"
  protocol_providers = [authentik_provider_proxy.uptime_kuma.id]
  service_connection = authentik_service_connection_kubernetes.cluster.id
  type               = "proxy"
}

resource "authentik_service_connection_kubernetes" "cluster" {
  kubeconfig = "{}"
  local      = true
  name       = "Homelab - Cluster"
  verify_ssl = true
}
