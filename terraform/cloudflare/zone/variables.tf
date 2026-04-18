variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

# ── SSL / TLS ─────────────────────────────────────────────────────────────────

variable "ssl_mode" {
  description = "SSL mode: off, flexible, full, strict"
  type        = string
  default     = "strict"
}

variable "min_tls_version" {
  description = "Minimum TLS version: 1.0, 1.1, 1.2, 1.3"
  type        = string
  default     = "1.2"
}

variable "always_use_https" {
  description = "Redirect all HTTP requests to HTTPS"
  type        = bool
  default     = true
}

# ── WAF ───────────────────────────────────────────────────────────────────────

variable "block_bots" {
  description = "Block requests identified as bots by Cloudflare"
  type        = bool
  default     = true
}

variable "allow_aws" {
  description = "Skip WAF rules for AWS IPs (ASN 16509) — needed for services that call back from AWS"
  type        = bool
  default     = false
}

variable "geo_block_enabled" {
  description = "Block all countries not in geo_allowlist"
  type        = bool
  default     = false
}

variable "geo_allowlist" {
  description = "Country codes allowed when geo_block_enabled = true"
  type        = list(string)
  default     = ["PT", "GB"]
}
