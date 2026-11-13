data "sops_file" "airflow_oidc" {
  source_file = "../../kubernetes/apps/addons/airflow/values.sops.yaml"
  input_type  = "yaml"
}

locals {
  airflow_oidc_values = yamldecode(data.sops_file.airflow_oidc.raw)
  airflow_oidc        = local.airflow_oidc_values.secret.stringData
}

resource "authentik_provider_oauth2" "airflow_oidc" {
  name                       = "Airflow Native OIDC"
  authentication_flow        = authentik_flow.login_choice.uuid
  depends_on                 = [authentik_flow_stage_binding.login_choice]
  authorization_flow         = authentik_flow.provider_authorization.uuid
  invalidation_flow          = authentik_flow.provider_logout.uuid
  client_id                  = local.airflow_oidc.AIRFLOW_OIDC_CLIENT_ID
  client_secret              = local.airflow_oidc.AIRFLOW_OIDC_CLIENT_SECRET
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  include_claims_in_id_token = true
  allowed_redirect_uris = [{
    matching_mode     = "strict"
    redirect_uri_type = "authorization"
    url               = "https://airflow.local.${local.apps_domain}/auth/oauth-authorized/authentik"
  }]
  signing_key       = authentik_certificate_key_pair.signing.id
  issuer_mode       = "per_provider"
  sub_mode          = "hashed_user_id"
  property_mappings = [authentik_property_mapping_provider_scope.oidc_openid.id]
}

resource "authentik_application" "airflow_oidc" {
  name               = "Airflow Native OIDC"
  slug               = "airflow"
  group              = "addons"
  protocol_provider  = authentik_provider_oauth2.airflow_oidc.id
  policy_engine_mode = "all"
}

resource "authentik_group" "airflow_oidc" {
  name         = "airflow-oidc"
  is_superuser = false
  parents      = []
  roles        = []
  users        = jsondecode(data.sops_file.secrets.data["airflow.oidc_user_ids"])
}

resource "authentik_policy_binding" "airflow_oidc" {
  target         = authentik_application.airflow_oidc.uuid
  group          = authentik_group.airflow_oidc.id
  order          = 0
  enabled        = true
  failure_result = false
}
