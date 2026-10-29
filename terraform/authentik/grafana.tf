data "sops_file" "grafana" {
  source_file = "../../kubernetes/apps/monitoring/grafana/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  grafana_values = yamldecode(data.sops_file.grafana.raw)
}

import {
  to = authentik_provider_oauth2.grafana
  id = nonsensitive(data.sops_file.secrets.data["grafana_provider_id"])
}

import {
  to = authentik_application.grafana
  id = "grafana"
}

resource "authentik_provider_oauth2" "grafana" {
  name                       = "Grafana OIDC"
  authentication_flow        = authentik_flow.login.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = "grafana"
  client_secret              = local.grafana_values.envRenderSecret.GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET
  client_type                = "confidential"
  grant_types                = ["authorization_code", "refresh_token"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "hours=1"
  refresh_token_validity     = "days=30"
  include_claims_in_id_token = true
  allowed_redirect_uris      = jsondecode(data.sops_file.secrets.data["grafana_redirect_uris"])
  signing_key                = data.sops_file.secrets.data["grafana_signing_key"]
  issuer_mode                = "per_provider"
  sub_mode                   = "user_uuid"
  property_mappings = [
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
  ]
}

resource "authentik_application" "grafana" {
  name               = "Grafana"
  slug               = "grafana"
  protocol_provider  = authentik_provider_oauth2.grafana.id
  policy_engine_mode = "any"
  meta_launch_url    = "https://${local.grafana_values.ingress.hosts[0]}"
}
