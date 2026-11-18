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
  group          = authentik_group.access["g1"].id
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
  group          = authentik_group.access["g1"].id
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

# The local password stage limits failed attempts per flow. Do not bind the
# shared IP reputation score to this flow: it denies a valid password and MFA
# before identification when unrelated failures have lowered the IP score.
