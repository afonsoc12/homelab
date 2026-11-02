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
  description = "Base domain used to build tunnel hostnames"
  type        = string
}

variable "k3s_cluster_secret" {
  description = "Base64-encoded tunnel secret for k3s-cluster"
  type        = string
  sensitive   = true
}

variable "spliit_access_emails" {
  description = "Email addresses allowed through Cloudflare Access on split.<domain>"
  type        = list(string)
  sensitive   = true
}

variable "authentik_idp_id" {
  description = "Authentik OIDC identity provider for Firefly Access"
  type        = string
}

variable "firefly_access_emails" {
  description = "Accounts allowed to access Firefly"
  type        = list(string)
  sensitive   = true
}

variable "access_team_name" {
  description = "Cloudflare Access team name used to validate tunnel JWTs"
  type        = string
  sensitive   = true
}
