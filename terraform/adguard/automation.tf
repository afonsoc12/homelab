resource "adguard_rewrite" "automation" {
  for_each = toset(["esphome", "z2m"])

  domain = "${each.value}.local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}
