# Use the same encrypted LoadBalancer address as the Contour Helm release.
data "sops_file" "contour" {
  source_file = "../../kubernetes/apps/ingress/contour/values.sops.yaml"
  input_type  = "yaml"
}

resource "adguard_rewrite" "grafana" {
  domain = "grafana.local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}
