resource "authentik_policy_reputation" "login_reputation" {
  check_ip          = true
  check_username    = true
  execution_logging = false
  name              = "Homelab - Login Reputation"
  threshold         = -5
}

resource "authentik_policy_expression" "account_authorization" {
  execution_logging = false
  expression        = data.sops_file.secrets.data["value_042"]
  name              = "Homelab - Account Authorization"
}

resource "authentik_policy_expression" "native_oidc_record_verified_email" {
  execution_logging = false
  name              = "Homelab - Record Verified Email Address"
  expression        = <<-PY
    user = request.context.get("pending_user")
    token = request.context.get("is_restored")
    if user and user.pk and user.email and token and token.user_id == user.pk:
        user.attributes["email_verified_address"] = user.email
        user.save(update_fields=["attributes"])
    return True
  PY
}

resource "authentik_policy_password" "password_change" {
  amount_digits           = 1
  amount_lowercase        = 1
  amount_symbols          = 1
  amount_uppercase        = 1
  check_have_i_been_pwned = true
  check_static_rules      = true
  check_zxcvbn            = true
  error_message           = "Use at least 15 characters with uppercase, lowercase, a number and a symbol. Common, predictable and breached passwords are rejected."
  execution_logging       = false
  hibp_allowed_count      = 0
  length_min              = 15
  name                    = "Homelab - Password Change"
  password_field          = "password" # Prompt field name. gitleaks:allow
  symbol_charset          = "!\\\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
  zxcvbn_score_threshold  = 3
}

resource "authentik_policy_password" "password_requirements" {
  amount_digits           = 1
  amount_lowercase        = 1
  amount_symbols          = 1
  amount_uppercase        = 1
  check_have_i_been_pwned = true
  check_static_rules      = true
  check_zxcvbn            = true
  error_message           = "Use at least 15 characters with uppercase, lowercase, a number and a symbol. Common, predictable and breached passwords are rejected."
  execution_logging       = false
  hibp_allowed_count      = 0
  length_min              = 15
  name                    = "Homelab - Password Requirements"
  password_field          = "password" # Prompt field name. gitleaks:allow
  symbol_charset          = "!\\\"#$%&'()*+,-./:;<=>?@[]^_`{|}~"
  zxcvbn_score_threshold  = 3
}

resource "authentik_policy_event_matcher" "event_configuration_error" {
  action            = "configuration_error"
  execution_logging = false
  name              = "Homelab - Event Configuration Error"
}

resource "authentik_policy_event_matcher" "event_configuration_warning" {
  action            = "configuration_warning"
  execution_logging = false
  name              = "Homelab - Event Configuration Warning"
}

resource "authentik_policy_event_matcher" "event_policy_exception" {
  action            = "policy_exception"
  execution_logging = false
  name              = "Homelab - Event Policy Exception"
}

resource "authentik_policy_event_matcher" "event_property_mapping_exception" {
  action            = "property_mapping_exception"
  execution_logging = false
  name              = "Homelab - Event Property Mapping Exception"
}

resource "authentik_policy_event_matcher" "event_update" {
  action            = "update_available"
  execution_logging = false
  name              = "Homelab - Event Update"
}
