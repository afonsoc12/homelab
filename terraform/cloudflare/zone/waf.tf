locals {
  geo_expr = "(not ip.geoip.country in {${join(" ", [for c in var.geo_allowlist : format("\"%s\"", c)])}})"

  aws_callback_paths_expr = join(" or ", [
    for host, paths in var.aws_callback_endpoints :
    "(http.host eq ${jsonencode("${host}.${var.domain}")} and http.request.uri.path in {${join(" ", [for path in sort(tolist(paths)) : jsonencode(path)])}})"
  ])

  # These are exceptions to the bot/country predicates, never a skip action.
  # AWS ownership remains only a network filter; endpoints must authenticate.
  aws_callback_expr = length(var.aws_callback_endpoints) > 0 ? "(ip.src.asnum eq 16509 and ssl and http.request.method eq \"POST\" and (${local.aws_callback_paths_expr}))" : "false"

  waf_rules = concat(
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
      expression  = length(var.aws_callback_endpoints) > 0 ? "(cf.client.bot and not ${local.aws_callback_expr})" : "(cf.client.bot)"
      enabled     = true
    }] : [],

    var.geo_block_enabled ? [{
      action      = "block"
      description = "Block all except ${join(", ", var.geo_allowlist)}"
      expression  = length(var.aws_callback_endpoints) > 0 ? "(${local.geo_expr} and not ${local.aws_callback_expr})" : local.geo_expr
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
