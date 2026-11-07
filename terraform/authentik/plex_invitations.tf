# The invite opens the same enrollment flow used by the Plex callback. Its
# admission policy validates the invite without consuming it before Plex login.
resource "authentik_policy_expression" "plex_enrollment_admission" {
  name              = "Homelab - Plex Invitation Admission"
  execution_logging = false
  expression        = file("${path.module}/policies/plex_enrollment.py")
}

resource "authentik_policy_binding" "plex_enrollment_admission" {
  target         = authentik_flow.plex["enrollment"].uuid
  policy         = authentik_policy_expression.plex_enrollment_admission.id
  order          = 0
  enabled        = true
  failure_result = false
}

resource "authentik_policy_expression" "plex_email_access" {
  name              = "Homelab - Plex Email Access"
  execution_logging = false
  expression = templatefile("${path.module}/policies/plex_email_access.py.tftpl", {
    denied_emails = jsonencode(local.plex_denied_emails)
  })
}

resource "authentik_policy_binding" "plex_email_access" {
  for_each       = authentik_flow.plex
  target         = each.value.uuid
  policy         = authentik_policy_expression.plex_email_access.id
  order          = 5
  enabled        = true
  failure_result = false
}

resource "authentik_stage_identification" "plex_invitation" {
  name                = "Homelab - Plex Invitation Sign In"
  user_fields         = []
  sources             = [authentik_source_plex.plex.uuid]
  show_source_labels  = true
  pretend_user_exists = false
  password_stage      = ""
  passwordless_flow   = ""
  enrollment_flow     = ""
  recovery_flow       = ""
  webauthn_stage      = ""
}

resource "authentik_flow_stage_binding" "plex_invitation_identification" {
  target                  = authentik_flow.plex["enrollment"].uuid
  stage                   = authentik_stage_identification.plex_invitation.id
  order                   = 0
  evaluate_on_plan        = true
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_expression" "plex_before_source" {
  name              = "Homelab - Plex Invitation Before Source"
  execution_logging = false
  expression        = "return not ak_is_sso_flow"
}

resource "authentik_policy_binding" "plex_before_source" {
  target         = authentik_flow_stage_binding.plex_invitation_identification.id
  policy         = authentik_policy_expression.plex_before_source.id
  order          = 0
  enabled        = true
  failure_result = false
}

# A source-only identification stage is presentation, not proof of identity.
# If it is skipped or fails to redirect, explicitly deny before consuming the
# invitation or creating a user. A policy error must execute this deny stage.
resource "authentik_stage_deny" "plex_unverified" {
  name = "Homelab - Deny Unverified Plex Enrollment"
}

resource "authentik_policy_expression" "plex_require_source" {
  name              = "Homelab - Reject Unverified Plex Enrollment"
  execution_logging = false
  expression = templatefile("${path.module}/policies/plex_source_context.py.tftpl", {
    deny_unverified = "True"
  })
}

resource "authentik_flow_stage_binding" "plex_require_source" {
  target                  = authentik_flow.plex["enrollment"].uuid
  stage                   = authentik_stage_deny.plex_unverified.id
  order                   = 5
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "plex_require_source" {
  target         = authentik_flow_stage_binding.plex_require_source.id
  policy         = authentik_policy_expression.plex_require_source.id
  order          = 0
  enabled        = true
  failure_result = true
}

resource "authentik_flow_stage_binding" "plex_invitation" {
  target                  = authentik_flow.plex["enrollment"].uuid
  stage                   = authentik_stage_invitation.invitation_enrollment.id
  order                   = 8
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}
