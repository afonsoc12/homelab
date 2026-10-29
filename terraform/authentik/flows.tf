resource "authentik_flow" "login" {
  authentication     = "none"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "authentication"
  layout             = "stacked"
  name               = "Homelab - Login"
  policy_engine_mode = "any"
  slug               = "homelab-login"
  title              = "Homelab Login"
}

resource "authentik_flow" "mfa_duo_setup" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - MFA Duo Setup"
  policy_engine_mode = "any"
  slug               = "homelab-mfa-duo-setup"
  title              = "Setup Duo Push Notifications"
}

resource "authentik_flow" "mfa_static_setup" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - MFA Static Setup"
  policy_engine_mode = "any"
  slug               = "homelab-mfa-static-setup"
  title              = "Setup Static OTP Tokens"
}

resource "authentik_flow" "mfa_totp_setup" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - MFA TOTP Setup"
  policy_engine_mode = "any"
  slug               = "homelab-mfa-totp-setup"
  title              = "Set up Two-Factor authentication"
}

resource "authentik_flow" "mfa_webauthn_setup" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - MFA WebAuthn Setup"
  policy_engine_mode = "any"
  slug               = "homelab-mfa-webauthn-setup"
  title              = "Setup WebAuthn"
}

resource "authentik_flow" "logout" {
  authentication     = "none"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "invalidation"
  layout             = "stacked"
  name               = "Homelab - Logout"
  policy_engine_mode = "any"
  slug               = "homelab-logout"
  title              = "Default Invalidation Flow"
}

resource "authentik_flow" "password_change" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - Password Change"
  policy_engine_mode = "any"
  slug               = "homelab-password-change"
  title              = "Change password"
}

resource "authentik_flow" "provider_consent" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "authorization"
  layout             = "stacked"
  name               = "Homelab - Provider Consent"
  policy_engine_mode = "any"
  slug               = "homelab-provider-consent"
  title              = "Continue to your application"
}

resource "authentik_flow" "provider_authorization" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "authorization"
  layout             = "stacked"
  name               = "Homelab - Provider Authorization"
  policy_engine_mode = "any"
  slug               = "homelab-provider-authorization"
  title              = "Signing you in"
}

resource "authentik_flow" "provider_logout" {
  authentication     = "none"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "invalidation"
  layout             = "stacked"
  name               = "Homelab - Provider Logout"
  policy_engine_mode = "any"
  slug               = "homelab-provider-logout"
  title              = "You have signed out"
}

resource "authentik_flow" "account_settings" {
  authentication     = "require_authenticated"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "stage_configuration"
  layout             = "stacked"
  name               = "Homelab - Account Settings"
  policy_engine_mode = "any"
  slug               = "homelab-account-settings"
  title              = "Update your info"
}

resource "authentik_flow" "invitation_enrollment" {
  authentication     = "none"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = true
  denied_action      = "message_continue"
  designation        = "enrollment"
  layout             = "stacked"
  name               = "Homelab - Invitation Enrollment"
  policy_engine_mode = "any"
  slug               = "homelab-invitation-enrollment"
  title              = "Enrollment Invitation"
}

resource "authentik_flow" "recovery" {
  authentication     = "none"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
  denied_action      = "message_continue"
  designation        = "recovery"
  layout             = "stacked"
  name               = "Homelab - Recovery"
  policy_engine_mode = "any"
  slug               = "homelab-recovery"
  title              = "Recovery"
}
