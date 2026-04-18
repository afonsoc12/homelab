# ── k3s-cluster ──────────────────────────────────────────────────────────────

resource "cloudflare_zero_trust_tunnel_cloudflared" "k3s_cluster" {
  account_id    = var.account_id
  name          = "k3s-cluster"
  tunnel_secret = var.k3s_cluster_secret
  # "cloudflare" means the tunnel config is managed remotely via
  # cloudflare_zero_trust_tunnel_cloudflared_config (not embedded locally).
  config_src = "cloudflare"

  lifecycle {
    # tunnel_secret: API never returns it on read, so import leaves it null.
    ignore_changes = [tunnel_secret]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "k3s_cluster" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.k3s_cluster.id

  config = {
    # Order matches Cloudflare state (first match wins)
    ingress = [
      {
        hostname = "auth.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "auth.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "firefly.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "firefly.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "home.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "home.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "seerr.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "seerr.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "calibre.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "calibre.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "rss.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "rss.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "status.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "status.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "wallabag.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "wallabag.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "git.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "git.${var.domain}"
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "git-ssh.${var.domain}"
        service  = "ssh://gitea-ssh.homelab"
      },
      {
        hostname = "sso.${var.domain}"
        service  = "https://ingress-nginx-controller"
        origin_request = {
          origin_server_name = "sso.${var.domain}"
        }
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

locals {
  k3s_cluster_subdomains = toset(["auth", "calibre", "firefly", "git", "git-ssh", "home", "rss", "seerr", "sso", "status", "wallabag"])
}

# Keys use "subdomain|CNAME" format to match import addresses
resource "cloudflare_dns_record" "k3s_cluster" {
  for_each = { for s in local.k3s_cluster_subdomains : "${s}|CNAME" => s }

  zone_id = var.zone_id
  name    = each.value
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k3s_cluster.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
