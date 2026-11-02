mock_provider "cloudflare" {}

variables {
  zone_id           = "00000000000000000000000000000000"
  domain            = "example.invalid"
  geo_block_enabled = true
}

run "no_aws_exception_by_default" {
  command = plan

  assert {
    condition     = length(cloudflare_ruleset.waf[0].rules) == 2
    error_message = "Without configured callbacks, only the bot and country rules should exist."
  }
}

run "exact_callback_contract" {
  command = plan

  variables {
    aws_callback_endpoints = {
      home                        = ["/auth/token", "/api/alexa/smart_home"]
      music-assistant-alexa-skill = ["/"]
    }
    github_webhook_rules = {
      allow_expression = "false"
      block_expression = "false"
    }
  }

  # This exact policy admits only POST from the existing AWS ASN. Host/path
  # pairs must stay separate: it must not allow POST / on home or the Home
  # Assistant APIs on the music callback hostname, unrelated hosts, or GET.
  assert {
    condition = cloudflare_ruleset.waf[0].rules[0].expression == join("", [
      "(ip.geoip.asnum eq 16509 and http.request.method eq \"POST\" and (",
      "(http.host eq \"home.example.invalid\" and http.request.uri.path in {\"/api/alexa/smart_home\" \"/auth/token\"})",
      " or (http.host eq \"music-assistant-alexa-skill.example.invalid\" and http.request.uri.path in {\"/\"})))",
    ])
    error_message = "AWS callbacks must match the exact source, method, hostname and documented endpoint pairs."
  }

  assert {
    condition = (
      length(cloudflare_ruleset.waf[0].rules) == 5 &&
      cloudflare_ruleset.waf[0].rules[0].action == "skip" &&
      cloudflare_ruleset.waf[0].rules[0].logging.enabled &&
      cloudflare_ruleset.waf[0].rules[0].action_parameters.ruleset == "current" &&
      cloudflare_ruleset.waf[0].rules[0].action_parameters.phases == null &&
      cloudflare_ruleset.waf[0].rules[0].action_parameters.products == null &&
      cloudflare_ruleset.waf[0].rules[1].description == "Allow GitHub webhook IPs" &&
      cloudflare_ruleset.waf[0].rules[2].description == "Block webhook requests outside GitHub IPs" &&
      cloudflare_ruleset.waf[0].rules[3].action == "block" &&
      cloudflare_ruleset.waf[0].rules[4].action == "block"
    )
    error_message = "Retain five custom rules, callback logging, webhook protections and bot/geo blocks; never skip other WAF phases or products."
  }
}

run "reject_wildcard_hostname" {
  command = plan
  variables {
    aws_callback_endpoints = { "*" = ["/auth/token"] }
  }
  expect_failures = [var.aws_callback_endpoints]
}

run "reject_wildcard_path" {
  command = plan
  variables {
    aws_callback_endpoints = { home = ["/api/*"] }
  }
  expect_failures = [var.aws_callback_endpoints]
}

run "reject_empty_path_list" {
  command = plan
  variables {
    aws_callback_endpoints = { home = [] }
  }
  expect_failures = [var.aws_callback_endpoints]
}

run "reject_missing_domain" {
  command = plan
  variables {
    domain                 = ""
    aws_callback_endpoints = { home = ["/auth/token"] }
  }
  expect_failures = [var.aws_callback_endpoints]
}
