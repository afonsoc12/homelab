resource "authentik_flow_stage_binding" "mfa_duo_setup" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 10
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_duo.mfa_duo_setup.id
  target                  = authentik_flow.mfa_duo_setup.uuid
}

resource "authentik_flow_stage_binding" "login_identification" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 10
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_identification.login_identification.id
  target                  = authentik_flow.login.uuid
}

resource "authentik_flow_stage_binding" "login_login" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 100
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_login.login_login.id
  target                  = authentik_flow.login.uuid
}

resource "authentik_flow_stage_binding" "login_mfa_validation" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 30
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_validate.login_mfa_validation.id
  target                  = authentik_flow.login.uuid
}

resource "authentik_flow_stage_binding" "login_password" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 20
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_password.login_password.id
  target                  = authentik_flow.login.uuid
}

resource "authentik_flow_stage_binding" "mfa_static_setup" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_static.mfa_static_setup.id
  target                  = authentik_flow.mfa_static_setup.uuid
}

resource "authentik_flow_stage_binding" "mfa_totp_setup" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_totp.mfa_totp_setup.id
  target                  = authentik_flow.mfa_totp_setup.uuid
}

resource "authentik_flow_stage_binding" "mfa_webauthn_setup" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_webauthn.mfa_webauthn_setup.id
  target                  = authentik_flow.mfa_webauthn_setup.uuid
}

resource "authentik_flow_stage_binding" "invalidation_logout" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_logout.invalidation_logout.id
  target                  = authentik_flow.logout.uuid
}

resource "authentik_flow_stage_binding" "password_change_prompt" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_prompt.password_change_prompt.id
  target                  = authentik_flow.password_change.uuid
}

resource "authentik_flow_stage_binding" "password_change_prompt_2" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 20
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_prompt.password_change_prompt.id
  target                  = authentik_flow.recovery.uuid
}

resource "authentik_flow_stage_binding" "password_change_write" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 1
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_write.password_change_write.id
  target                  = authentik_flow.password_change.uuid
}

resource "authentik_flow_stage_binding" "password_change_write_3" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 30
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_write.password_change_write.id
  target                  = authentik_flow.recovery.uuid
}

resource "authentik_flow_stage_binding" "provider_authorization_consent" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_consent.provider_authorization_consent.id
  target                  = authentik_flow.provider_consent.uuid
}

resource "authentik_flow_stage_binding" "source_enrollment_login_2" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 40
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_login.source_enrollment_login.id
  target                  = authentik_flow.invitation_enrollment.uuid
}

resource "authentik_flow_stage_binding" "source_enrollment_prompt_2" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 20
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_prompt.source_enrollment_prompt.id
  target                  = authentik_flow.invitation_enrollment.uuid
}

resource "authentik_flow_stage_binding" "user_settings" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 20
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_prompt.user_settings.id
  target                  = authentik_flow.account_settings.uuid
}

resource "authentik_flow_stage_binding" "account_write" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 100
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_write.account_write.id
  target                  = authentik_flow.account_settings.uuid
}

resource "authentik_flow_stage_binding" "invitation_enrollment" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 10
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_invitation.invitation_enrollment.id
  target                  = authentik_flow.invitation_enrollment.uuid
}

resource "authentik_flow_stage_binding" "enrollment_invitation_write" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 30
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_user_write.enrollment_invitation_write.id
  target                  = authentik_flow.invitation_enrollment.uuid
}

resource "authentik_flow_stage_binding" "recovery_authentication_identification" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 0
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_identification.recovery_authentication_identification.id
  target                  = authentik_flow.recovery.uuid
}

resource "authentik_flow_stage_binding" "recovery_email" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 10
  policy_engine_mode      = "any"
  re_evaluate_policies    = true
  stage                   = authentik_stage_email.recovery_email.id
  target                  = authentik_flow.recovery.uuid
}

# Both login and invitation enrollment must validate/enroll MFA before creating
# a session. Keep these bindings unconditional: a false stage policy skips MFA.
resource "authentik_flow_stage_binding" "invitation_mfa_validation" {
  evaluate_on_plan        = false
  invalid_response_action = "retry"
  order                   = 35
  policy_engine_mode      = "all"
  re_evaluate_policies    = true
  stage                   = authentik_stage_authenticator_validate.login_mfa_validation.id
  target                  = authentik_flow.invitation_enrollment.uuid
}
