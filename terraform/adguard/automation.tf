data "sops_file" "argocd" {
  source_file = "../../kubernetes/apps/addons/argocd/values.sops.yaml"
  input_type  = "yaml"
}

resource "adguard_rewrite" "automation" {
  for_each = toset(["airflow", "esphome", "grocy", "music-assistant", "n8n", "node-red", "z2m"])

  domain = "${each.value}.local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "argocd" {
  domain = data.sops_file.argocd.data["global.domain"]
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}
