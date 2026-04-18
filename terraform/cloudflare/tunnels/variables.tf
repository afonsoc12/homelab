variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "zone_id" {
  description = "Cloudflare zone ID for the base domain"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Base domain used to build tunnel hostnames (e.g. mydata247.top)"
  type        = string
}

variable "k3s_cluster_secret" {
  description = "Base64-encoded tunnel secret for k3s-cluster"
  type        = string
  sensitive   = true
}
