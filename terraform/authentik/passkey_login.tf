# An optional, discoverable passkey path. The existing password and Plex
# choices stay available while users enroll and test independent credentials.
resource "authentik_flow" "passkey_login" {
  name               = "Homelab - Passkey Sign In"
  slug               = "homelab-passkey-sign-in"
  title              = "Sign in with a passkey"
  designation        = "authentication"
  authentication     = "require_unauthenticated"
  policy_engine_mode = "all"
  denied_action      = "message_continue"
  layout             = "stacked"
}

resource "authentik_stage_authenticator_validate" "passkey_login" {
  name                          = "Homelab - Passkey Sign In"
  device_classes                = ["webauthn"]
  configuration_stages          = []
  not_configured_action         = "deny"
  last_auth_threshold           = "seconds=0"
  webauthn_user_verification    = "required"
  webauthn_allowed_device_types = []
  webauthn_hints                = []
}

resource "authentik_flow_stage_binding" "passkey_login_validate" {
  target                  = authentik_flow.passkey_login.uuid
  stage                   = authentik_stage_authenticator_validate.passkey_login.id
  order                   = 10
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

# Bind the proof to this browser session and account immediately after the
# WebAuthn assertion. The later password/email steps must not reset its age.
resource "authentik_policy_expression" "record_passkey_assertion" {
  name              = "Homelab - Record Passkey Assertion"
  execution_logging = false
  expression        = <<-PY
    from django.utils.timezone import now

    user = context.get("pending_user")
    http = request.http_request
    if not user or not user.pk or not http:
        return True
    if context["flow_plan"].context.get("auth_method") != "auth_webauthn_pwl":
        return True
    http.session["homelab/passkey_proof"] = {
        "user_id": user.pk,
        "asserted_at": now().isoformat(),
    }
    return False
  PY
}

resource "authentik_stage_deny" "passkey_assertion_missing" {
  name = "Homelab - Fresh Passkey Assertion Required"
}

resource "authentik_flow_stage_binding" "record_passkey_assertion" {
  target                  = authentik_flow.passkey_login.uuid
  stage                   = authentik_stage_deny.passkey_assertion_missing.id
  order                   = 11
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "record_passkey_assertion" {
  target         = authentik_flow_stage_binding.record_passkey_assertion.id
  policy         = authentik_policy_expression.record_passkey_assertion.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

# A valid assertion must resolve to an active persisted account before
# verification email, a possible password check, or a session is issued.
resource "authentik_flow_stage_binding" "passkey_login_active" {
  target                  = authentik_flow.passkey_login.uuid
  stage                   = authentik_stage_deny.inactive_account.id
  order                   = 12
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "passkey_login_active" {
  target         = authentik_flow_stage_binding.passkey_login_active.id
  policy         = authentik_policy_expression.inactive_account.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

# This stage is evaluated after the passkey assertion and email check. A
# password-bearing account must prove its EXISTING password when the last
# successful local-password proof is absent or at least 30 days old.
resource "authentik_policy_expression" "local_password_proof_due" {
  name              = "Homelab - Local Password Proof Due"
  execution_logging = false
  expression        = <<-PY
    from datetime import timedelta
    from django.utils.dateparse import parse_datetime
    from django.utils.timezone import now

    user = context.get("pending_user")
    if not user or not user.pk:
        return True
    current = ak_user_by(pk=user.pk)
    if not current or not current.is_active:
        return True
    if not current.has_usable_password():
        return False
    proof = parse_datetime(current.attributes.get("homelab_last_local_password_proof", ""))
    current_time = now()
    due = not proof or proof.tzinfo is None or proof > current_time or current_time - proof >= timedelta(days=30)
    if due:
        context["flow_plan"].context["homelab_local_password_due"] = current.pk
    return due
  PY
}

resource "authentik_flow_stage_binding" "local_password_proof" {
  for_each = {
    passkey = authentik_flow.passkey_login.uuid
  }
  target                  = each.value
  stage                   = authentik_stage_password.login_password.id
  order                   = 60
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "local_password_proof_due" {
  for_each       = authentik_flow_stage_binding.local_password_proof
  target         = each.value.id
  policy         = authentik_policy_expression.local_password_proof_due.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

# A Deny stage with a false result lets this expression persist the proof only
# after the dedicated password stage has set the inbuilt backend in this plan.
# Errors execute Deny. A second gate below rechecks the persisted timestamp.
resource "authentik_policy_expression" "record_local_password_proof" {
  name              = "Homelab - Record Local Password Proof"
  execution_logging = false
  expression        = <<-PY
    from django.utils.timezone import now

    user = context.get("pending_user")
    plan = context["flow_plan"].context
    if not user or not user.pk:
        return True
    current = ak_user_by(pk=user.pk)
    if not current or not current.is_active:
        return True
    if not current.has_usable_password():
        return False
    if plan.get("homelab_local_password_due") != current.pk:
        return False
    if plan.get("user_backend") != "authentik.core.auth.InbuiltBackend":
        return True
    current.attributes["homelab_last_local_password_proof"] = now().isoformat()
    current.save(update_fields=["attributes"])
    return False
  PY
}

# The ordinary local path already checks a password on every sign-in. Record
# that proof as well, so changing to the passkey choice does not immediately
# ask for the same password again.
resource "authentik_policy_expression" "record_local_login_password_proof" {
  name              = "Homelab - Record Local Login Password Proof"
  execution_logging = false
  expression        = <<-PY
    from django.utils.timezone import now

    user = context.get("pending_user")
    plan = context["flow_plan"].context
    if not user or not user.pk or plan.get("user_backend") != "authentik.core.auth.InbuiltBackend":
        return True
    current = ak_user_by(pk=user.pk)
    if not current or not current.is_active or not current.has_usable_password():
        return True
    current.attributes["homelab_last_local_password_proof"] = now().isoformat()
    current.save(update_fields=["attributes"])
    return False
  PY
}

resource "authentik_flow_stage_binding" "record_local_login_password_proof" {
  target                  = authentik_flow.login.uuid
  stage                   = authentik_stage_deny.local_password_proof_incomplete.id
  order                   = 96
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "record_local_login_password_proof" {
  target         = authentik_flow_stage_binding.record_local_login_password_proof.id
  policy         = authentik_policy_expression.record_local_login_password_proof.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_stage_deny" "local_password_proof_incomplete" {
  name = "Homelab - Local Password Proof Incomplete"
}

resource "authentik_flow_stage_binding" "record_local_password_proof" {
  for_each                = authentik_flow_stage_binding.local_password_proof
  target                  = each.value.target
  stage                   = authentik_stage_deny.local_password_proof_incomplete.id
  order                   = 70
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "record_local_password_proof" {
  for_each       = authentik_flow_stage_binding.record_local_password_proof
  target         = each.value.id
  policy         = authentik_policy_expression.record_local_password_proof.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_policy_expression" "passkey_assertion_stale" {
  name              = "Homelab - Passkey Assertion Stale"
  execution_logging = false
  expression        = <<-PY
    from datetime import timedelta
    from django.utils.dateparse import parse_datetime
    from django.utils.timezone import now

    user = context.get("pending_user")
    http = request.http_request
    if not user or not user.pk or not http:
        return True
    proof = http.session.get("homelab/passkey_proof", {})
    if proof.get("user_id") != user.pk:
        return True
    asserted_at = parse_datetime(proof.get("asserted_at", ""))
    current_time = now()
    return not asserted_at or asserted_at.tzinfo is None or asserted_at > current_time or current_time - asserted_at >= timedelta(hours=6)
  PY
}

resource "authentik_flow_stage_binding" "passkey_assertion_stale" {
  target                  = authentik_flow.passkey_login.uuid
  stage                   = authentik_stage_deny.passkey_assertion_missing.id
  order                   = 85
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "passkey_assertion_stale" {
  target         = authentik_flow_stage_binding.passkey_assertion_stale.id
  policy         = authentik_policy_expression.passkey_assertion_stale.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_flow_stage_binding" "local_password_proof_incomplete" {
  for_each                = authentik_flow_stage_binding.local_password_proof
  target                  = each.value.target
  stage                   = authentik_stage_deny.local_password_proof_incomplete.id
  order                   = 90
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "local_password_proof_incomplete" {
  for_each       = authentik_flow_stage_binding.local_password_proof_incomplete
  target         = each.value.id
  policy         = authentik_policy_expression.local_password_proof_due.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

# The existing Plex path receives the same monthly check in a later rollout
# stage, after the optional passkey path has been exercised.
resource "authentik_flow_stage_binding" "plex_local_password_proof" {
  target                  = authentik_flow.plex["authentication"].uuid
  stage                   = authentik_stage_password.login_password.id
  order                   = 60
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "plex_local_password_proof_due" {
  target         = authentik_flow_stage_binding.plex_local_password_proof.id
  policy         = authentik_policy_expression.local_password_proof_due.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_flow_stage_binding" "plex_record_local_password_proof" {
  target                  = authentik_flow.plex["authentication"].uuid
  stage                   = authentik_stage_deny.local_password_proof_incomplete.id
  order                   = 70
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "plex_record_local_password_proof" {
  target         = authentik_flow_stage_binding.plex_record_local_password_proof.id
  policy         = authentik_policy_expression.record_local_password_proof.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_flow_stage_binding" "plex_local_password_proof_incomplete" {
  target                  = authentik_flow.plex["authentication"].uuid
  stage                   = authentik_stage_deny.local_password_proof_incomplete.id
  order                   = 97
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "plex_local_password_proof_incomplete" {
  target         = authentik_flow_stage_binding.plex_local_password_proof_incomplete.id
  policy         = authentik_policy_expression.local_password_proof_due.id
  order          = 0
  enabled        = true
  failure_result = true
  timeout        = 0
}

resource "authentik_flow_stage_binding" "passkey_login_session" {
  # The direct flow URL must not issue a session while Terraform is still
  # creating its mandatory passkey, email and password-proof gates.
  depends_on = [
    authentik_flow_stage_binding.passkey_login_validate,
    authentik_policy_binding.record_passkey_assertion,
    authentik_policy_binding.passkey_login_active,
    authentik_policy_binding.signin_email_required["passkey"],
    authentik_policy_binding.signin_email_destination["passkey"],
    authentik_policy_binding.signin_email_complete["passkey"],
    authentik_policy_binding.local_password_proof_due["passkey"],
    authentik_policy_binding.record_local_password_proof["passkey"],
    authentik_policy_binding.passkey_assertion_stale,
    authentik_policy_binding.local_password_proof_incomplete["passkey"],
  ]
  target                  = authentik_flow.passkey_login.uuid
  stage                   = authentik_stage_user_login.login_login.id
  order                   = 100
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}
