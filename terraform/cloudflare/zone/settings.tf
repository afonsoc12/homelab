locals {
  settings = {
    # SSL / TLS
    ssl                      = var.ssl_mode
    min_tls_version          = var.min_tls_version
    always_use_https         = var.always_use_https ? "on" : "off"
    tls_1_3                  = "on"
    opportunistic_encryption = "on"
    automatic_https_rewrites = "on"

    # Performance (skip http2, http3, early_hints - not editable on free plan)
    brotli = "on"

    # Security
    security_level = "medium"
    browser_check  = "on"
    # Skip visitor_ip - not editable

    # Network
    ipv6 = "on"
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}
