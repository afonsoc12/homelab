resource "authentik_policy_binding" "notification_update" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 0
  policy         = authentik_policy_event_matcher.event_update.id
  target         = authentik_event_rule.notify_update.id
  timeout        = 30
}

resource "authentik_policy_binding" "access_uptime_kuma" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 0
  target         = authentik_application.uptime_kuma.uuid
  timeout        = 30
  user           = tonumber(data.sops_file.secrets.data["value_078"])
}

resource "authentik_policy_binding" "access_node_red" {
  enabled        = true
  failure_result = false
  group          = data.sops_file.secrets.data["value_079"]
  negate         = false
  order          = 0
  target         = authentik_application.node_red.uuid
  timeout        = 30
}

resource "authentik_policy_binding" "notification_policy_exception" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 0
  policy         = authentik_policy_event_matcher.event_policy_exception.id
  target         = authentik_event_rule.notify_exception.id
  timeout        = 30
}

resource "authentik_policy_binding" "access_argo_cd" {
  enabled        = true
  failure_result = false
  group          = data.sops_file.secrets.data["value_079"]
  negate         = false
  order          = 0
  target         = authentik_application.argo_cd.uuid
  timeout        = 30
}

resource "authentik_policy_binding" "notification_configuration_error" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 0
  policy         = authentik_policy_event_matcher.event_configuration_error.id
  target         = authentik_event_rule.notify_configuration_error.id
  timeout        = 30
}

resource "authentik_policy_binding" "notification_configuration_warning" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 0
  policy         = authentik_policy_event_matcher.event_configuration_warning.id
  target         = authentik_event_rule.notify_configuration_warning.id
  timeout        = 30
}

resource "authentik_policy_binding" "notification_property_mapping_exception" {
  enabled        = true
  failure_result = false
  negate         = false
  order          = 1
  policy         = authentik_policy_event_matcher.event_property_mapping_exception.id
  target         = authentik_event_rule.notify_exception.id
  timeout        = 30
}

resource "authentik_policy_binding" "login_mfa_required" {
  enabled        = true
  failure_result = true
  negate         = false
  order          = 10
  policy         = authentik_policy_expression.login_mfa_required.id
  target         = authentik_flow_stage_binding.login_mfa_validation.id
  timeout        = 30
}

resource "authentik_policy_binding" "login_password_required" {
  enabled        = true
  failure_result = true
  negate         = false
  order          = 10
  policy         = authentik_policy_expression.login_password_required.id
  target         = authentik_flow_stage_binding.login_password.id
  timeout        = 30
}

resource "authentik_policy_binding" "login_identification_reputation" {
  target = authentik_flow_stage_binding.login_identification.id
  policy = authentik_policy_reputation.login_reputation.id # login-brute-force-protection
  order  = 0
  negate = true
}

resource "authentik_policy_binding" "login_mfa_reputation" {
  target = authentik_flow_stage_binding.login_mfa_validation.id
  policy = authentik_policy_reputation.login_reputation.id # login-brute-force-protection
  order  = 0
  negate = true
}
