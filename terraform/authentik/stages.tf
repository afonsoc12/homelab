resource "authentik_stage_authenticator_duo" "mfa_duo_setup" {
  admin_integration_key = ""
  api_hostname          = data.sops_file.secrets.data["value_022"]
  client_id             = data.sops_file.secrets.data["value_023"]
  client_secret         = data.sops_file.secrets.data["value_024"]
  configure_flow        = authentik_flow.mfa_duo_setup.uuid
  friendly_name         = "Duo Push Notification"
  name                  = "Homelab - MFA Duo Setup"
}

resource "authentik_stage_authenticator_static" "mfa_static_setup" {
  configure_flow = authentik_flow.mfa_static_setup.uuid
  friendly_name  = "Static tokens"
  name           = "Homelab - MFA Static Setup"
  token_count    = 6
  token_length   = 12
}

resource "authentik_stage_authenticator_totp" "mfa_totp_setup" {
  configure_flow = authentik_flow.mfa_totp_setup.uuid
  digits         = "6"
  friendly_name  = "TOTP Device"
  name           = "Homelab - MFA TOTP Setup"
}

resource "authentik_stage_authenticator_validate" "login_mfa_validation" {
  # Recovery codes can satisfy MFA, but must not be the only enrollment option.
  configuration_stages = [
    authentik_stage_authenticator_totp.mfa_totp_setup.id,
    authentik_stage_authenticator_duo.mfa_duo_setup.id,
    authentik_stage_authenticator_webauthn.mfa_webauthn_setup.id,
  ]
  device_classes                = ["static", "totp", "webauthn", "duo"]
  email_otp_throttling_factor   = 1
  last_auth_threshold           = "seconds=0"
  name                          = "Homelab - Login MFA Validation"
  not_configured_action         = "configure"
  sms_otp_throttling_factor     = 1
  static_otp_throttling_factor  = 1
  totp_otp_throttling_factor    = 1
  webauthn_allowed_device_types = []
  webauthn_hints                = []
  webauthn_user_verification    = "preferred"
}

resource "authentik_stage_authenticator_webauthn" "mfa_webauthn_setup" {
  configure_flow           = authentik_flow.mfa_webauthn_setup.uuid
  device_type_restrictions = []
  friendly_name            = "WebAuthn device"
  hints                    = []
  max_attempts             = 0
  name                     = "Homelab - MFA WebAuthn Setup"
  resident_key_requirement = "preferred"
  user_verification        = "preferred"
}

resource "authentik_stage_consent" "provider_authorization_consent" {
  consent_expire_in = "weeks=4"
  mode              = "expiring"
  name              = "Homelab - Provider Authorization Consent"
}

resource "authentik_stage_email" "recovery_email" {
  activate_user_on_success = true
  from_address             = data.sops_file.secrets.data["value_055"]
  host                     = "localhost"
  name                     = "Homelab - Recovery Email"
  port                     = 25
  recovery_cache_timeout   = "minutes=30"
  recovery_max_attempts    = 3
  subject                  = "Password Recovery authentik"
  template                 = "email/password_reset.html"
  timeout                  = 10
  token_expiry             = "minutes=30"
  use_global_settings      = true
  use_ssl                  = false
  use_tls                  = false
  username                 = ""
}

resource "authentik_stage_identification" "login_identification" {
  captcha_stage             = ""
  case_insensitive_matching = true
  enable_remember_me        = false
  enrollment_flow           = ""
  name                      = "Homelab - Login Identification"
  password_stage            = authentik_stage_password.login_password.id
  passwordless_flow         = ""
  pretend_user_exists       = true
  recovery_flow             = authentik_flow.recovery.uuid
  show_matched_user         = true
  show_source_labels        = false
  sources                   = []
  user_fields               = ["email", "username"]
  webauthn_stage            = ""
}

resource "authentik_stage_identification" "recovery_authentication_identification" {
  captcha_stage             = ""
  case_insensitive_matching = true
  enable_remember_me        = false
  enrollment_flow           = ""
  name                      = "Homelab - Recovery Authentication Identification"
  password_stage            = ""
  passwordless_flow         = ""
  pretend_user_exists       = true
  recovery_flow             = ""
  show_matched_user         = true
  show_source_labels        = false
  sources                   = []
  user_fields               = ["username", "email"]
  webauthn_stage            = ""
}

resource "authentik_stage_invitation" "invitation_enrollment" {
  continue_flow_without_invitation = false
  name                             = "Homelab - Invitation Enrollment"
}

resource "authentik_stage_password" "login_password" {
  allow_show_password           = false
  backends                      = ["authentik.core.auth.InbuiltBackend", "authentik.sources.kerberos.auth.KerberosBackend", "authentik.sources.ldap.auth.LDAPBackend", "authentik.core.auth.TokenBackend"]
  configure_flow                = authentik_flow.password_change.uuid
  failed_attempts_before_cancel = 5
  name                          = "Homelab - Login Password"
}

resource "authentik_stage_prompt" "password_change_prompt" {
  fields              = [authentik_stage_prompt_field.password_change_password.id, authentik_stage_prompt_field.password_change_password_repeat.id]
  name                = "Homelab - Password Change Prompt"
  validation_policies = [authentik_policy_password.password_change.id]
}

resource "authentik_stage_prompt" "source_enrollment_prompt" {
  fields              = [authentik_stage_prompt_field.account_email.id, authentik_stage_prompt_field.account_username.id, authentik_stage_prompt_field.invitation_password.id, authentik_stage_prompt_field.account_name.id, authentik_stage_prompt_field.invitation_password_repeat.id]
  name                = "Homelab - Source Enrollment Prompt"
  validation_policies = [authentik_policy_password.password_requirements.id]
}

resource "authentik_stage_prompt" "user_settings" {
  fields              = [authentik_stage_prompt_field.account_username.id, authentik_stage_prompt_field.account_name.id, authentik_stage_prompt_field.account_locale.id, authentik_stage_prompt_field.account_email.id]
  name                = "Homelab - User Settings"
  validation_policies = [authentik_policy_expression.account_authorization.id]
}

resource "authentik_stage_user_login" "login_login" {
  geoip_binding            = "no_binding"
  name                     = "Homelab - Login Login"
  network_binding          = "no_binding"
  remember_device          = "days=30"
  remember_me_offset       = "seconds=0"
  session_duration         = "weeks=1"
  terminate_other_sessions = false
}

resource "authentik_stage_user_login" "source_enrollment_login" {
  geoip_binding            = "no_binding"
  name                     = "Homelab - Source Enrollment Login"
  network_binding          = "no_binding"
  remember_device          = "days=30"
  remember_me_offset       = "seconds=0"
  session_duration         = "seconds=0"
  terminate_other_sessions = false
}

resource "authentik_stage_user_logout" "invalidation_logout" {
  name = "Homelab - Invalidation Logout"
}

resource "authentik_stage_user_write" "password_change_write" {
  create_users_as_inactive = false
  create_users_group       = ""
  name                     = "Homelab - Password Change Write"
  user_creation_mode       = "never_create"
  user_path_template       = ""
  user_type                = "external"
}

resource "authentik_stage_user_write" "account_write" {
  create_users_as_inactive = false
  create_users_group       = ""
  name                     = "Homelab - Account Write"
  user_creation_mode       = "never_create"
  user_path_template       = ""
  user_type                = "external"
}

resource "authentik_stage_user_write" "enrollment_invitation_write" {
  create_users_as_inactive = false
  create_users_group       = ""
  name                     = "Homelab - Enrollment Invitation Write"
  user_creation_mode       = "always_create"
  user_path_template       = "users"
  user_type                = "internal"
}

resource "authentik_stage_prompt_field" "account_locale" {
  field_key                = data.sops_file.secrets.data["value_056"]
  initial_value            = data.sops_file.secrets.data["value_057"]
  initial_value_expression = true
  label                    = "Locale"
  name                     = "Homelab - Account Locale"
  order                    = 203
  placeholder              = "Locale"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "ak-locale"
}

resource "authentik_stage_prompt_field" "account_email" {
  field_key                = "email"
  initial_value            = data.sops_file.secrets.data["value_058"]
  initial_value_expression = true
  label                    = "Email"
  name                     = "Homelab - Account Email"
  order                    = 202
  placeholder              = "Email"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "email"
}

resource "authentik_stage_prompt_field" "account_name" {
  field_key                = "name"
  initial_value            = data.sops_file.secrets.data["value_059"]
  initial_value_expression = true
  label                    = "Name"
  name                     = "Homelab - Account Name"
  order                    = 201
  placeholder              = "Name"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "text"
}

resource "authentik_stage_prompt_field" "password_change_password" {
  field_key                = "password"
  initial_value            = ""
  initial_value_expression = false
  label                    = "Password"
  name                     = "Homelab - Password Change Password"
  order                    = 300
  placeholder              = "Password"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "password"
}

resource "authentik_stage_prompt_field" "invitation_password" {
  field_key                = "password"
  initial_value            = ""
  initial_value_expression = false
  label                    = "Password"
  name                     = "Homelab - Invitation Password"
  order                    = 300
  placeholder              = "Password"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "password"
}

resource "authentik_stage_prompt_field" "invitation_password_repeat" {
  field_key                = "password_repeat"
  initial_value            = ""
  initial_value_expression = false
  label                    = "Password (repeat)"
  name                     = "Homelab - Invitation Password Repeat"
  order                    = 301
  placeholder              = "Password (repeat)"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "password"
}

resource "authentik_stage_prompt_field" "password_change_password_repeat" {
  field_key                = "password_repeat"
  initial_value            = ""
  initial_value_expression = false
  label                    = "Password (repeat)"
  name                     = "Homelab - Password Change Password Repeat"
  order                    = 301
  placeholder              = "Password (repeat)"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "password"
}

resource "authentik_stage_prompt_field" "account_username" {
  field_key                = "username"
  initial_value            = data.sops_file.secrets.data["value_060"]
  initial_value_expression = true
  label                    = "Username"
  name                     = "Homelab - Account Username"
  order                    = 200
  placeholder              = "Username"
  placeholder_expression   = false
  required                 = true
  sub_text                 = ""
  type                     = "username"
}
