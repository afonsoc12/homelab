locals {
  geo_expr = "(not ip.geoip.country in {${join(" ", [for c in var.geo_allowlist : format("\"%s\"", c)])}})"

  waf_rules = concat(
    # The Alexa skill accepts signed callbacks at POST /. AWS hosting alone
    # grants no exception on any other hostname, method or path.
    length(var.aws_callback_hosts) > 0 ? [{
      action      = "skip"
      description = "Allow AWS callbacks only on configured endpoints"
      expression  = "(ip.geoip.asnum eq 16509 and http.host in {${join(" ", [for host in sort(tolist(var.aws_callback_hosts)) : format("\"%s.%s\"", host, var.domain)])}} and http.request.method eq \"POST\" and http.request.uri.path eq \"/\")"
      action_parameters = {
        ruleset = "current"
      }
      logging = { enabled = true }
      enabled = true
    }] : [],

    # Keep the source allowlist and its matching deny rule together, before
    # general bot/geo checks. Neither expression is stored in plaintext.
    var.github_webhook_rules != null ? [
      {
        action      = "skip"
        description = "Allow GitHub webhook IPs"
        expression  = var.github_webhook_rules.allow_expression
        action_parameters = {
          ruleset = "current"
        }
        logging = { enabled = true }
        enabled = true
      },
    ] : [],

    var.github_webhook_rules != null ? [
      {
        action            = "block"
        description       = "Block webhook requests outside GitHub IPs"
        expression        = var.github_webhook_rules.block_expression
        action_parameters = null
        logging           = null
        enabled           = true
      },
    ] : [],

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
      logging           = try(r.logging, null)
      action_parameters = can(r.action_parameters) ? r.action_parameters : null
    }
  ]
}
