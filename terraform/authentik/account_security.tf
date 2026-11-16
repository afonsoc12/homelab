# Email proves inbox control; it supplements password/source authentication and
# MFA. It never activates an account or replaces an existing second factor.
resource "authentik_stage_email" "signin_verification" {
  name                     = "Homelab - Sign In Email Verification"
  use_global_settings      = true
  activate_user_on_success = false
  from_address             = data.sops_file.secrets.data["value_055"]
  subject                  = "Verify your sign in"
  template                 = "email/account_confirmation.html"
  token_expiry             = "minutes=15"
  recovery_max_attempts    = 3
  recovery_cache_timeout   = "minutes=30"
}

# Email precedes factor enrollment for a new or changed address, so knowing a
# password alone cannot register an authenticator before inbox control is proved.
resource "authentik_flow_stage_binding" "signin_email" {
  for_each = {
    login         = { flow = authentik_flow.login.uuid, order = 20 }
    passkey       = { flow = authentik_flow.passkey_login.uuid, order = 15 }
    invitation    = { flow = authentik_flow.invitation_enrollment.uuid, order = 32 }
    plex_login    = { flow = authentik_flow.plex["authentication"].uuid, order = 15 }
    plex_login_v2 = { flow = authentik_flow.plex_auth_v2.uuid, order = 15 }
    plex_join     = { flow = authentik_flow.plex["enrollment"].uuid, order = 15 }
  }
  target                  = each.value.flow
  stage                   = authentik_stage_email.signin_verification.id
  order                   = each.value.order
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

# Once the current address has been verified, subsequent sign-ins only need
# password and MFA. Enrollment continues to run the Email stage unconditionally.
resource "authentik_policy_expression" "signin_email_required" {
  name              = "Homelab - Sign In Email Verification Required"
  execution_logging = false
  expression        = <<-PY
    user = context.get("pending_user")
    if not user or not user.pk or not user.is_active or not user.email:
        return True
    current = ak_user_by(pk=user.pk)
    return not current or not current.is_active or not current.email or current.attributes.get("email_verified_address") != current.email
  PY
}

resource "authentik_policy_binding" "signin_email_required" {
  for_each = {
    login         = authentik_flow_stage_binding.signin_email["login"].id
    passkey       = authentik_flow_stage_binding.signin_email["passkey"].id
    plex_login    = authentik_flow_stage_binding.signin_email["plex_login"].id
    plex_login_v2 = authentik_flow_stage_binding.signin_email["plex_login_v2"].id
  }
  target         = each.value
  policy         = authentik_policy_expression.signin_email_required.id
  order          = 0
  enabled        = true
  timeout        = contains(["passkey", "plex_login_v2"], each.key) ? 0 : 30
  failure_result = true # Evaluation errors require email verification.
}

# Capture the actual destination in server-side plan context before minting the
# email token. Refuse verification if the saved address changes while it is out.
resource "authentik_policy_expression" "signin_email_destination_invalid" {
  name              = "Homelab - Capture Sign In Email Destination"
  execution_logging = false
  expression        = <<-PY
    user = context.get("pending_user")
    if not user or not user.pk or not user.is_active or not user.email:
        return True
    # An invitation/source must not redirect this message to another inbox.
    context.pop("email", None)
    context["flow_plan"].context.pop("email", None)
    context["flow_plan"].context["signin_email_address"] = user.email
    return False
  PY
}

resource "authentik_flow_stage_binding" "signin_email_destination" {
  for_each = {
    login         = { flow = authentik_flow.login.uuid, order = 19 }
    passkey       = { flow = authentik_flow.passkey_login.uuid, order = 14 }
    invitation    = { flow = authentik_flow.invitation_enrollment.uuid, order = 31 }
    plex_login    = { flow = authentik_flow.plex["authentication"].uuid, order = 14 }
    plex_login_v2 = { flow = authentik_flow.plex_auth_v2.uuid, order = 14 }
    plex_join     = { flow = authentik_flow.plex["enrollment"].uuid, order = 14 }
  }
  target                  = each.value.flow
  stage                   = authentik_stage_deny.signin_email_incomplete.id
  order                   = each.value.order
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "signin_email_destination" {
  for_each       = authentik_flow_stage_binding.signin_email_destination
  target         = each.value.id
  policy         = authentik_policy_expression.signin_email_destination_invalid.id
  order          = 0
  enabled        = true
  timeout        = contains(["passkey", "plex_login_v2"], each.key) ? 0 : 30
  failure_result = true
}

resource "authentik_stage_authenticator_validate" "existing_mfa" {
  name                         = "Homelab - Verify Existing MFA"
  device_classes               = ["static", "totp", "webauthn", "duo"]
  configuration_stages         = []
  not_configured_action        = "deny"
  last_auth_threshold          = "seconds=0"
  static_otp_throttling_factor = 1
  totp_otp_throttling_factor   = 1
  webauthn_user_verification   = "required"
}

# Recovery must never offer enrollment of a new MFA device as proof of identity.
# Require a fresh existing factor before changing passwords/profile or issuing
# more recovery codes. The recovery binding follows successful email verification.
resource "authentik_flow_stage_binding" "sensitive_action_mfa" {
  for_each = {
    recovery = { flow = authentik_flow.recovery.uuid, order = 15 }
    password = { flow = authentik_flow.password_change.uuid, order = -10 }
    settings = { flow = authentik_flow.account_settings.uuid, order = 10 }
    codes    = { flow = authentik_flow.mfa_static_setup.uuid, order = -10 }
    totp     = { flow = authentik_flow.mfa_totp_setup.uuid, order = -10 }
    webauthn = { flow = authentik_flow.mfa_webauthn_setup.uuid, order = -10 }
    duo      = { flow = authentik_flow.mfa_duo_setup.uuid, order = -10 }
  }
  target                  = each.value.flow
  stage                   = authentik_stage_authenticator_validate.existing_mfa.id
  order                   = each.value.order
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

# Present single-use recovery codes after primary MFA enrollment, before login.
resource "authentik_flow_stage_binding" "enrollment_recovery_codes" {
  for_each = {
    invitation = { flow = authentik_flow.invitation_enrollment.uuid, order = 38 }
    plex       = { flow = authentik_flow.plex["enrollment"].uuid, order = 25 }
  }
  target                  = each.value.flow
  stage                   = authentik_stage_authenticator_static.mfa_static_setup.id
  order                   = each.value.order
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_stage_deny" "inactive_account" {
  name = "Homelab - Deny Inactive Account"
}

resource "authentik_policy_expression" "inactive_account" {
  name              = "Homelab - Account Must Be Active"
  execution_logging = false
  expression        = <<-PY
    user = context.get("pending_user") or request.user
    # Unknown identifiers must reach the Email stage's generic response.
    # Persisted inactive accounts must never receive recovery tokens.
    if not user or not user.pk:
        return False
    current = ak_user_by(pk=user.pk)
    return not current or not current.is_active
  PY
}

resource "authentik_flow_stage_binding" "recovery_inactive_account" {
  for_each = {
    before_write = 25
  }
  target                  = authentik_flow.recovery.uuid
  stage                   = authentik_stage_deny.inactive_account.id
  order                   = each.value
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "recovery_inactive_account" {
  for_each       = authentik_flow_stage_binding.recovery_inactive_account
  target         = each.value.id
  policy         = authentik_policy_expression.inactive_account.id
  order          = 0
  enabled        = true
  failure_result = true # An evaluation error executes the Deny stage.
}

# The pinned server throttles resends but not the first send of a new flow.
# Bound initial requests too. Unknown, inactive and throttled accounts all reach
# the same native Email sent challenge with an unsaved placeholder and no token.
resource "authentik_policy_expression" "recovery_prepare" {
  name              = "Homelab - Prepare Private Recovery"
  execution_logging = false
  expression        = <<-PY
    from hashlib import sha256
    from django.core.cache import cache
    from authentik.core.models import User

    user = context.get("pending_user")
    if not user:
        return True
    identifier = (user.email or user.username).strip().casefold()
    key = "homelab/recovery/start/" + sha256(identifier.encode()).hexdigest()
    cache.add(key, 0, timeout=1800)
    attempts = cache.incr(key)
    current = ak_user_by(pk=user.pk) if user.pk else None
    if not current or not current.is_active or attempts > 3:
        placeholder = User(username=user.username, email=user.email)
        context["pending_user"] = placeholder
        context["flow_plan"].context["pending_user"] = placeholder
    return False
  PY
}

resource "authentik_flow_stage_binding" "recovery_prepare" {
  target                  = authentik_flow.recovery.uuid
  stage                   = authentik_stage_deny.inactive_account.id
  order                   = 5
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "recovery_prepare" {
  target         = authentik_flow_stage_binding.recovery_prepare.id
  policy         = authentik_policy_expression.recovery_prepare.id
  order          = 0
  enabled        = true
  failure_result = true
}

resource "authentik_policy_binding" "recovery_reputation" {
  target         = authentik_flow.recovery.uuid
  policy         = authentik_policy_reputation.login_reputation.id
  order          = 0
  negate         = true
  enabled        = true
  failure_result = false
}

# A recovered password invalidates authentik's existing password-based sessions.
# End this browser session too, and return users to the complete sign-in flow.
resource "authentik_flow_stage_binding" "recovery_logout" {
  target                  = authentik_flow.recovery.uuid
  stage                   = authentik_stage_user_logout.invalidation_logout.id
  order                   = 100
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  invalid_response_action = "retry"
}

# Local sign-in already verifies the existing password on every new login.
# A 30-day proof record is needed before a password-bearing account can use
# passkey primary sign-in; the old 365-day password-change gate was rotation.

resource "authentik_policy_expression" "password_not_current" {
  name              = "Homelab - Require A Different Password"
  execution_logging = false
  expression        = <<-PY
    user = context.get("pending_user") or request.user
    password = context.get("prompt_data", {}).get("password")
    if not user or not user.pk or not password:
        return False
    if user.has_usable_password() and user.check_password(password):
        ak_message("Choose a different password from your current password.")
        return False
    return True
  PY
}

# Record inbox control only after a token issued by our sign-in Email stage is
# restored for this account. A previously verified, unchanged address also
# satisfies this guard. Bind to Deny rather than User Login:
# policy errors must stop authentication, never skip a required check.
resource "authentik_policy_expression" "signin_email_incomplete" {
  name              = "Homelab - Sign In Email Must Be Verified"
  execution_logging = false
  expression        = <<-PY
    user = context.get("pending_user")
    token = context.get("is_restored")
    if not user or not user.pk or not user.is_active or not user.email:
        return True
    current = ak_user_by(pk=user.pk)
    if not current or not current.is_active or not current.email:
        return True
    if current.attributes.get("email_verified_address") == current.email:
        return False
    if not token or token.user_id != user.pk:
        return True
    if not token.identifier.startswith("ak-email-stage-homelab-sign-in-email-verification-"):
        return True
    address = context["flow_plan"].context.get("signin_email_address")
    if not address or current.email != address:
        return True
    current.attributes["email_verified_address"] = address
    current.save(update_fields=["attributes"])
    return False
  PY
}

resource "authentik_stage_deny" "signin_email_incomplete" {
  name = "Homelab - Email Verification Incomplete"
}

resource "authentik_flow_stage_binding" "signin_email_complete" {
  for_each = {
    login         = { flow = authentik_flow.login.uuid, order = 95 }
    passkey       = { flow = authentik_flow.passkey_login.uuid, order = 50 }
    invitation    = { flow = authentik_flow.invitation_enrollment.uuid, order = 39 }
    plex_login    = { flow = authentik_flow.plex["authentication"].uuid, order = 95 }
    plex_login_v2 = { flow = authentik_flow.plex_auth_v2.uuid, order = 95 }
    plex_join     = { flow = authentik_flow.plex["enrollment"].uuid, order = 95 }
  }
  target                  = each.value.flow
  stage                   = authentik_stage_deny.signin_email_incomplete.id
  order                   = each.value.order
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_policy_binding" "signin_email_complete" {
  for_each       = authentik_flow_stage_binding.signin_email_complete
  target         = each.value.id
  policy         = authentik_policy_expression.signin_email_incomplete.id
  order          = 0
  enabled        = true
  timeout        = contains(["passkey", "plex_login_v2"], each.key) ? 0 : 30
  failure_result = true
}
