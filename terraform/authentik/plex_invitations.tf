# The invite opens the same enrollment flow used by the Plex callback. Its
# admission policy validates the invite without consuming it before Plex login.
resource "authentik_policy_expression" "plex_enrollment_admission" {
  name              = "Homelab - Plex Invitation Admission"
  execution_logging = false
  expression        = <<-PY
    # Authentik expression policy: validate, but do not consume, the invitation.
    from uuid import UUID

    from authentik.stages.invitation.models import Invitation
    from django.utils.timezone import now

    query = http_request.session.get("authentik/flows/get", {})
    profile = context.get("prompt_data", {})
    token = query.get("itoken") or query.get("token") or profile.get("token")
    if not token:
        return False
    try:
        invitation_id = UUID(str(token))
    except (ValueError, TypeError, AttributeError):
        return False

    invitation = Invitation.objects.filter(
        pk=invitation_id,
        flow__slug="homelab-plex-enrollment",
        single_use=True,
        expiring=True,
    ).first()
    if (
        invitation is None
        or invitation.expires is None
        or invitation.expires <= now()
        or invitation.fixed_data
    ):
        return False

    if not ak_is_sso_flow:
        # Only the source-selection stage can run before Plex proves identity.
        # A separate deny stage blocks any attempt to proceed without that proof.
        return True

    source = context.get("source")
    connection = context.get("goauthentik.io/sources/connection")
    if not (
        source is not None
        and source.enabled
        and source.slug == "plex"
        and connection is not None
        and connection.source_id == source.pk
        and connection.identifier
    ):
        return False

    # The Plex callback redirects without the original invitation query string.
    # Keep its token in the server-side flow plan for the native Invitation stage,
    # which revalidates and consumes the single-use invitation after Plex login.
    profile["token"] = str(invitation_id)
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
# If it is skipped or fails to redirect, explicitly deny before consuming the
# invitation or creating a user. A policy error must execute this deny stage.
resource "authentik_stage_deny" "plex_unverified" {
  name = "Homelab - Deny Unverified Plex Enrollment"
}

resource "authentik_policy_expression" "plex_require_source" {
  name              = "Homelab - Reject Unverified Plex Enrollment"
  execution_logging = false
  expression        = <<-PY
    source = context.get("source")
    connection = context.get("goauthentik.io/sources/connection")
    verified = bool(
        ak_is_sso_flow
        and source is not None
        and source.enabled
        and source.slug == "plex"
        and connection is not None
        and connection.source_id == source.pk
        and connection.identifier
    )
    return not verified
  PY
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
