data "http" "github_meta" {
  count = var.allow_github_hooks ? 1 : 0

  url = "https://api.github.com/meta"
}

locals {
  geo_expr = "(not ip.geoip.country in {${join(" ", [for c in var.geo_allowlist : format("\"%s\"", c)])}})"

  # GitHub's published webhook-delivery source IPs, fetched live so this
  # allowlist doesn't silently rot as GitHub rotates ranges.
  github_hook_cidrs = var.allow_github_hooks ? jsondecode(data.http.github_meta[0].response_body)["hooks"] : []

  waf_rules = concat(
    # Allow AWS first so bot/geo rules don't block legitimate AWS callbacks
    var.allow_aws ? [{
      action      = "skip"
      description = "Allow AWS"
      expression  = "(ip.geoip.asnum eq 16509)"
      action_parameters = {
        ruleset = "current"
      }
      enabled = true
    }] : [],

    # Deny-by-default on this hostname regardless of geography — the geo rule
    # below only blocks *non*-PT/GB traffic, so without this explicit block
    # anyone physically in PT/GB could reach the mirror-sync hook too. Only
    # GitHub's own published webhook source IPs may reach this hostname.
    var.allow_github_hooks ? [{
      action      = "block"
      description = "Block git-hook.${var.domain} except from GitHub's webhook IPs"
      expression  = "(http.host eq \"git-hook.${var.domain}\" and not (ip.src in {${join(" ", local.github_hook_cidrs)}}))"
      enabled     = true
    }] : [],

    var.block_bots ? [{
      action      = "block"
      description = "Block bots"
      expression  = "(cf.client.bot)"
      enabled     = true
    }] : [],

    var.geo_block_enabled ? [{
      action      = "block"
      description = "Block all except ${join(", ", var.geo_allowlist)}"
      expression  = local.geo_expr
      enabled     = true
    }] : [],
  )
}

resource "cloudflare_ruleset" "waf" {
  count = length(local.waf_rules) > 0 ? 1 : 0

  zone_id     = var.zone_id
  name        = "Custom WAF rules"
  description = "Managed by Terraform"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    for r in local.waf_rules : {
      action            = r.action
      description       = r.description
      expression        = r.expression
      enabled           = r.enabled
      action_parameters = can(r.action_parameters) ? r.action_parameters : null
    }
  ]
}
