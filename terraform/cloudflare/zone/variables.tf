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

variable "aws_callback_endpoints" {
  description = "Exact subdomain/path pairs whose POST endpoints accept AWS callbacks without custom geo/bot filtering"
  type        = map(set(string))
  default     = {}

  validation {
    condition = alltrue([
      for host, paths in var.aws_callback_endpoints :
      can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", host)) &&
      length(paths) > 0 &&
      alltrue([for path in paths : can(regex("^/[A-Za-z0-9/_-]*$", path))])
    ])
    error_message = "AWS callbacks require individual subdomain labels and nonempty exact paths, without wildcards, queries or encoded characters."
  }

  validation {
    condition     = length(var.aws_callback_endpoints) == 0 || length(trimspace(var.domain)) > 0
    error_message = "A base domain is required when AWS callbacks are configured."
  }
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

variable "domain" {
  description = "Base domain — required when AWS callback exceptions are configured"
  type        = string
  default     = ""
}

variable "github_webhook_rules" {
  description = "Paired GitHub webhook source rules supplied from encrypted configuration"
  type = object({
    allow_expression = string
    block_expression = string
  })
  default = null
}
