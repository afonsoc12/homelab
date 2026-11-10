locals {
  domain        = data.sops_file.secrets.data["domain"]
  oci_public_ip = data.sops_file.secrets.data["oci_public_ip"]
}

resource "adguard_rewrite" "local" {
  domain = "local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "local-wildcard" {
  domain = "*.local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "db" {
  domain = "db.local.${local.domain}"
  answer = "10.0.10.223"
}

resource "adguard_rewrite" "mqtt" {
  domain = "mqtt.local.${local.domain}"
  answer = "10.0.10.221"
}

resource "adguard_rewrite" "home" {
  domain = "home.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "calibre" {
  domain = "calibre.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "firefly" {
  domain = "firefly.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "sso" {
  domain = "sso.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "rss" {
  domain = "rss.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "stocks" {
  domain = "stocks.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "seerr" {
  domain = "seerr.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "plex" {
  domain = "plex.${local.domain}"
  answer = local.oci_public_ip
}

resource "adguard_rewrite" "status" {
  domain = "status.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "wallabag" {
  domain = "wallabag.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "music-assistant-alexa-skill" {
  domain = "music-assistant-alexa-skill.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "music-assistant-stream" {
  domain = "music-assistant-stream.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

resource "adguard_rewrite" "hoarder" {
  domain = "hoarder.srv.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}

# Preserve resource addresses while moving the last LAN hosts to Contour.
resource "adguard_rewrite" "legacy_local" {
  for_each = toset(["kopia", "unifi"])

  domain = "${each.value}.local.${local.domain}"
  answer = data.sops_file.contour.data["envoy.service.loadBalancerIP"]
}
