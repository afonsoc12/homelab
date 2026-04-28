resource "adguard_config" "main" {
  filtering = {
    enabled         = true
    update_interval = 24
  }

  safebrowsing = true

  safesearch = {
    enabled = false
  }

  querylog = {
    enabled             = true
    interval            = 1440 # 60 days
    anonymize_client_ip = false
  }

  stats = {
    enabled  = true
    interval = 1440 # 60 days
  }

  dns = {
    upstream_dns = [
      "tls://one.one.one.one",
      "tls://8.8.8.8",
    ]
    fallback_dns = [
      "1.1.1.1",
      "8.8.8.8",
    ]
    bootstrap_dns = [
      "1.1.1.1",
      "8.8.8.8",
    ]
    rate_limit         = 30
    blocking_mode      = "default"
    dnssec_enabled     = true
    cache_enabled      = true
    cache_optimistic   = true
    upstream_mode      = "parallel"
    upstream_timeout   = 5
    resolve_clients    = true
    protection_enabled = true
  }

  #   lifecycle {
  #     # Provider bug: tls fields return unknown after apply (gmichels/adguard#<issue>)
  #     # Without this, every apply taints the resource → next run hits DHCP 400 on replace
  #     ignore_changes = [tls]
  #   }
}
