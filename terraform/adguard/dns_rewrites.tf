locals {
  domain        = data.sops_file.secrets.data["domain"]
  oci_public_ip = data.sops_file.secrets.data["oci_public_ip"]
}

resource "adguard_rewrite" "local" {
  domain = "local.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "local-wildcard" {
  domain = "*.local.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "home" {
  domain = "home.local.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "firefly" {
  domain = "firefly.local.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "db" {
  domain = "db.local.${local.domain}"
  answer = "10.0.10.223"
}

resource "adguard_rewrite" "sso" {
  domain = "sso.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "auth" {
  domain = "auth.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "rss" {
  domain = "rss.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "stocks" {
  domain = "stocks.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "plex" {
  domain = "plex.${local.domain}"
  answer = local.oci_public_ip
}

resource "adguard_rewrite" "status" {
  domain = "status.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "wallabag" {
  domain = "wallabag.${local.domain}"
  answer = "10.0.10.220"
}

resource "adguard_rewrite" "hoarder" {
  domain = "hoarder.srv.${local.domain}"
  answer = "10.0.10.220"
}
