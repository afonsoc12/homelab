data "sops_file" "longhorn" {
  source_file = "../../kubernetes/apps/longhorn-system/longhorn/values.sops.yaml"
  input_type  = "yaml"
}

resource "adguard_rewrite" "longhorn" {
  domain = data.sops_file.longhorn.data["ingress.host"]
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}
