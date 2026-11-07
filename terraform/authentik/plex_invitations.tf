# The invite opens the same enrollment flow used by the Plex callback. Its
# callback policy preserves its token for the native Invitation stage.
resource "authentik_policy_expression" "plex_enrollment_admission" {
  name              = "Homelab - Plex Invitation Admission"
  execution_logging = false
  expression        = <<-PY
    # Keep the invite token across Plex's callback. The native Invitation
    # stage validates its UUID, expiry, flow, and whether it was already used.
    query = http_request.session.get("authentik/flows/get", {})
    profile = context.get("prompt_data", {})
    token = query.get("itoken") or query.get("token") or profile.get("token")
    if not token:
        return False
    if ak_is_sso_flow:
        profile["token"] = token
    return True
  PY
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
  expression        = <<-PY
    # The initial invitation entry has no Plex profile yet. Both callbacks must
    # provide an email, checked case-insensitively against the encrypted denylist.
    if not ak_is_sso_flow:
        return True

    email = str(context.get("prompt_data", {}).get("email") or "").strip().casefold()
    denied_emails = ${jsonencode(local.plex_denied_emails)}
    return bool(email) and email not in {
        value.strip().casefold() for value in denied_emails
    }
  PY
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
# After native invitation validation, require proven Plex identity and a
# single-use, expiring invite before creating a user. Policy errors execute denial.
resource "authentik_stage_deny" "plex_unverified" {
  name = "Homelab - Deny Unverified Plex Enrollment"
}

resource "authentik_policy_expression" "plex_require_source" {
  name              = "Homelab - Reject Unverified Plex Enrollment"
  execution_logging = false
  expression        = <<-PY
    source = context.get("source")
    connection = context.get("goauthentik.io/sources/connection")
    invitation = context.get("invitation")
    verified = bool(
        ak_is_sso_flow
        and source is not None
        and source.enabled
        and source.slug == "plex"
        and connection is not None
        and connection.source_id == source.pk
        and connection.identifier
        and invitation is not None
        and invitation.flow_id is not None
        and invitation.single_use
        and invitation.expiring
        and invitation.expires is not None
        and not invitation.fixed_data
    )
    return not verified
  PY
}

resource "authentik_flow_stage_binding" "plex_require_source" {
  target                  = authentik_flow.plex["enrollment"].uuid
  stage                   = authentik_stage_deny.plex_unverified.id
  order                   = 9
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

# Do not consume an invite until Plex has proved identity. If this check fails,
# the later deny stage rejects the missing native invitation result.
resource "authentik_policy_binding" "plex_invitation_source" {
  target         = authentik_flow_stage_binding.plex_invitation.id
  policy         = authentik_policy_expression.plex_source_context.id
  order          = 0
  enabled        = true
  failure_result = false
}
