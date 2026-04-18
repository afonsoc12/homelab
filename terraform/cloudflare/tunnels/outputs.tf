output "k3s_cluster_token" {
  description = "Cloudflare tunnel token for k3s-cluster (base64-encoded JSON credentials)"
  value = base64encode(jsonencode({
    a = var.account_id
    t = cloudflare_zero_trust_tunnel_cloudflared.k3s_cluster.id
    s = var.k3s_cluster_secret
  }))
  sensitive = true
}
