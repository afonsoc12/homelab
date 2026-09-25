# The login-brute-force-protection reputation policy returns True only when
# reputation is BAD (score <= threshold). These bindings must be negated so the
# stage is skipped only for bad-reputation clients, not included only for them.
# Without negate=true, the identification/MFA stages never show for normal
# users (score 0), and the login flow skips straight to the password stage.

resource "authentik_policy_binding" "identification_brute_force" {
  target = "7d846cdd-36c3-4b2d-b4b8-828751b745ae" # default-authentication-identification
  policy = "9da36d6a-ec74-4d04-b4b3-d32169267e76" # login-brute-force-protection
  order  = 0
  negate = true
}

resource "authentik_policy_binding" "mfa_validation_brute_force" {
  target = "f8f95328-793b-4184-af0b-02ec9c693372" # default-authentication-mfa-validation
  policy = "9da36d6a-ec74-4d04-b4b3-d32169267e76" # login-brute-force-protection
  order  = 0
  negate = true
}
