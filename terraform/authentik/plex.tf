# Plex proves identity; application bindings independently grant access.
locals {
  plex_client_id       = try(data.sops_file.secrets.data["plex.client_id"], "homelab-authentik")
  plex_token           = try(data.sops_file.secrets.data["plex.token"], "")
  plex_allowed_servers = jsondecode(try(data.sops_file.secrets.data["plex.allowed_servers"], "[]"))
}

resource "authentik_source_plex" "plex" {
  name                = "Plex"
  slug                = "plex"
  enabled             = true
  promoted            = true
  client_id           = local.plex_client_id
  plex_token          = local.plex_token
  allowed_servers     = local.plex_allowed_servers
  allow_friends       = false
  user_matching_mode  = "identifier"
  group_matching_mode = "identifier"
  user_path_template  = "users/plex"
  policy_engine_mode  = "all"
  authentication_flow = authentik_flow.plex["authentication"].uuid
  enrollment_flow     = authentik_flow.plex["enrollment"].uuid

  # Do not expose the source until app restrictions and every authentication
  # safeguard exist, even when Terraform creates independent resources in parallel.
  depends_on = [
    authentik_policy_binding.access_mealie,
    authentik_policy_binding.access_grafana,
    authentik_policy_binding.plex_source_context,
    authentik_policy_binding.plex_reputation,
    authentik_flow_stage_binding.plex_enrollment_write,
    authentik_flow_stage_binding.plex_mfa,
    authentik_flow_stage_binding.plex_login,
  ]

  lifecycle {
    precondition {
      condition = (
        length(local.plex_allowed_servers) > 0 &&
        alltrue([for server in local.plex_allowed_servers : length(trimspace(server)) > 0])
      )
      error_message = "Plex sign-in requires an explicit allowed server."
    }
    precondition {
      condition     = length(trimspace(local.plex_token)) > 0
      error_message = "Plex sign-in requires an encrypted Plex token."
    }
  }
}

resource "authentik_flow" "plex" {
  for_each           = toset(["authentication", "enrollment"])
  name               = "Homelab - Plex ${title(each.key)}"
  slug               = "homelab-plex-${each.key}"
  title              = "Sign in with Plex"
  designation        = each.key
  authentication     = "require_unauthenticated"
  policy_engine_mode = "all"
  denied_action      = "message_continue"
  layout             = "stacked"
}

# These flows must only run after Authentik has redeemed a valid Plex token
# and checked the user's access to our selected Plex server. Direct flow URLs
# must never create users or authenticate a pending user without that proof.
resource "authentik_policy_expression" "plex_source_context" {
  name              = "Homelab - Verified Plex Source Context"
  execution_logging = false
  expression        = <<-PY
    source = context.get("source")
    connection = context.get("goauthentik.io/sources/connection")
    return bool(
        ak_is_sso_flow
        and source is not None
        and source.enabled
        and source.slug == "plex"
        and connection is not None
        and connection.source_id == source.pk
        and connection.identifier
    )
  PY
}

resource "authentik_policy_binding" "plex_source_context" {
  for_each       = authentik_flow.plex
  target         = each.value.uuid
  policy         = authentik_policy_expression.plex_source_context.id
  order          = 0
  enabled        = true
  failure_result = false
}

# Bind reputation to the whole flow: a failed stage policy only skips a stage.
resource "authentik_policy_binding" "plex_reputation" {
  for_each       = authentik_flow.plex
  target         = each.value.uuid
  policy         = authentik_policy_reputation.login_reputation.id
  negate         = true
  order          = 10
  enabled        = true
  failure_result = false
}

# No prompt, password, invitation attributes, or automatic group assignment.
# Plex supplies the profile; administrators manage memberships independently.
resource "authentik_stage_user_write" "plex_enrollment" {
  name                     = "Homelab - Plex Enrollment Write"
  user_creation_mode       = "always_create"
  create_users_as_inactive = false
  create_users_group       = ""
  user_path_template       = "users/plex"
  user_type                = "internal"
}

resource "authentik_flow_stage_binding" "plex_enrollment_write" {
  target                  = authentik_flow.plex["enrollment"].uuid
  stage                   = authentik_stage_user_write.plex_enrollment.id
  order                   = 10
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

# Unconditional MFA before either flow creates an authenticated session.
resource "authentik_flow_stage_binding" "plex_mfa" {
  for_each                = authentik_flow.plex
  target                  = each.value.uuid
  stage                   = authentik_stage_authenticator_validate.login_mfa_validation.id
  order                   = 20
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}

resource "authentik_stage_user_login" "plex" {
  name                     = "Homelab - Plex Login"
  session_duration         = "hours=8"
  remember_me_offset       = "seconds=0"
  remember_device          = "seconds=0"
  network_binding          = "no_binding"
  geoip_binding            = "no_binding"
  terminate_other_sessions = false
}

resource "authentik_flow_stage_binding" "plex_login" {
  for_each                = authentik_flow.plex
  target                  = each.value.uuid
  stage                   = authentik_stage_user_login.plex.id
  order                   = 100
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  policy_engine_mode      = "all"
  invalid_response_action = "retry"
}
