resource "authentik_certificate_key_pair" "signing" {
  certificate_data = data.sops_file.secrets.data["value_077"]
  key_data         = data.sops_file.secrets.data["value_005"]
  name             = "Homelab - Signing"
}

resource "authentik_service_connection_kubernetes" "cluster" {
  kubeconfig = "{}"
  local      = true
  name       = "Homelab - Cluster"
  verify_ssl = true
}
