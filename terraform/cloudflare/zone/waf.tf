locals {
  geo_expr = "(not ip.geoip.country in {${join(" ", [for c in var.geo_allowlist : format("\"%s\"", c)])}})"

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
