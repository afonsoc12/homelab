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

resource "authentik_policy_password" "password_change" {
  amount_digits           = 0
  amount_lowercase        = 0
  amount_symbols          = 0
  amount_uppercase        = 0
  check_have_i_been_pwned = false
  check_static_rules      = true
  check_zxcvbn            = true
  error_message           = "Password needs to be 8 characters or longer."
  execution_logging       = false
  hibp_allowed_count      = 0
  length_min              = 8
  name                    = "Homelab - Password Change"
  password_field          = "password" # Prompt field name. gitleaks:allow
  symbol_charset          = "!\\\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
  zxcvbn_score_threshold  = 2
}

resource "authentik_policy_password" "password_requirements" {
  amount_digits           = 1
  amount_lowercase        = 1
  amount_symbols          = 1
  amount_uppercase        = 1
  check_have_i_been_pwned = true
  check_static_rules      = true
  check_zxcvbn            = true
  error_message           = ""
  execution_logging       = false
  hibp_allowed_count      = 0
  length_min              = 12
  name                    = "Homelab - Password Requirements"
  password_field          = "password" # Prompt field name. gitleaks:allow
  symbol_charset          = "!\\\"#$%&'()*+,-./:;<=>?@[]^_`{|}~"
  zxcvbn_score_threshold  = 2
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
