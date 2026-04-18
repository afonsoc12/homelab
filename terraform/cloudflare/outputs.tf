output "tunnel_k3s_cluster_token" {
  description = "Cloudflare tunnel token for k3s-cluster"
  value       = module.tunnels.k3s_cluster_token
  sensitive   = true
}
