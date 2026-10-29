resource "authentik_application" "argo_cd" {
  backchannel_providers = []
  group                 = ""
  meta_description      = ""
  meta_hide             = false
  meta_icon             = data.sops_file.secrets.data["value_061"]
  meta_launch_url       = ""
  meta_publisher        = ""
  name                  = data.sops_file.secrets.data["value_062"]
  open_in_new_tab       = false
  policy_engine_mode    = "any"
  protocol_provider     = authentik_provider_oauth2.argo_cd.id
  slug                  = data.sops_file.secrets.data["value_063"]
  uuid                  = data.sops_file.secrets.data["value_064"]
}

resource "authentik_application" "mealie" {
  backchannel_providers = []
  group                 = ""
  meta_description      = ""
  meta_hide             = false
  meta_icon             = data.sops_file.secrets.data["value_065"]
  meta_launch_url       = ""
  meta_publisher        = ""
  name                  = data.sops_file.secrets.data["value_066"]
  open_in_new_tab       = true
  policy_engine_mode    = "any"
  protocol_provider     = authentik_provider_oauth2.mealie.id
  slug                  = data.sops_file.secrets.data["value_067"]
  uuid                  = data.sops_file.secrets.data["value_068"]
}

resource "authentik_application" "node_red" {
  backchannel_providers = []
  group                 = data.sops_file.secrets.data["value_069"]
  meta_description      = ""
  meta_hide             = false
  meta_icon             = ""
  meta_launch_url       = data.sops_file.secrets.data["value_003"]
  meta_publisher        = data.sops_file.secrets.data["value_070"]
  name                  = data.sops_file.secrets.data["value_071"]
  open_in_new_tab       = false
  policy_engine_mode    = "any"
  protocol_provider     = authentik_provider_oauth2.node_red.id
  slug                  = data.sops_file.secrets.data["value_072"]
  uuid                  = data.sops_file.secrets.data["value_073"]
}

resource "authentik_application" "uptime_kuma" {
  backchannel_providers = []
  group                 = ""
  meta_description      = ""
  meta_hide             = false
  meta_icon             = ""
  meta_launch_url       = data.sops_file.secrets.data["value_004"]
  meta_publisher        = ""
  name                  = "Homelab Protected Apps"
  open_in_new_tab       = false
  policy_engine_mode    = "any"
  protocol_provider     = authentik_provider_proxy.uptime_kuma.id
  slug                  = data.sops_file.secrets.data["value_075"]
  uuid                  = data.sops_file.secrets.data["value_076"]
}

resource "authentik_provider_oauth2" "argo_cd" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "hours=12"
  allowed_redirect_uris      = jsondecode(data.sops_file.secrets.data["value_010"])
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_011"]
  client_secret              = data.sops_file.secrets.data["value_012"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "implicit", "hybrid", "refresh_token", "client_credentials", "password", "urn:ietf:params:oauth:grant-type:device_code"]
  include_claims_in_id_token = true
  invalidation_flow          = authentik_flow.provider_logout.uuid
  issuer_mode                = "per_provider"
  jwt_federation_providers   = []
  jwt_federation_sources     = []
  logout_method              = "backchannel"
  logout_uri                 = ""
  name                       = "ArgoCD"
  property_mappings          = [authentik_property_mapping_provider_scope.oidc_openid.id, authentik_property_mapping_provider_scope.oidc_email.id, authentik_property_mapping_provider_scope.oidc_profile.id]
  refresh_token_threshold    = "seconds=0"
  refresh_token_validity     = "days=30"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"
}

resource "authentik_provider_oauth2" "mealie" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  allowed_redirect_uris      = jsondecode(data.sops_file.secrets.data["value_013"])
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_014"]
  client_secret              = data.sops_file.secrets.data["value_015"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "hybrid", "implicit", "client_credentials", "password", "urn:ietf:params:oauth:grant-type:device_code", "refresh_token"]
  include_claims_in_id_token = true
  invalidation_flow          = authentik_flow.provider_logout.uuid
  issuer_mode                = "per_provider"
  jwt_federation_providers   = []
  jwt_federation_sources     = []
  logout_method              = "backchannel"
  logout_uri                 = ""
  name                       = "Mealie"
  property_mappings          = [authentik_property_mapping_provider_scope.mealie_email_verified.id, authentik_property_mapping_provider_scope.oidc_profile.id]
  refresh_token_threshold    = "seconds=0"
  refresh_token_validity     = "days=30"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"
}

resource "authentik_provider_oauth2" "node_red" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  allowed_redirect_uris      = jsondecode(data.sops_file.secrets.data["value_016"])
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_017"]
  client_secret              = data.sops_file.secrets.data["value_018"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "hybrid", "implicit", "client_credentials", "password", "urn:ietf:params:oauth:grant-type:device_code", "refresh_token"]
  include_claims_in_id_token = true
  invalidation_flow          = authentik_flow.provider_logout.uuid
  issuer_mode                = "per_provider"
  jwt_federation_providers   = []
  jwt_federation_sources     = []
  logout_method              = "backchannel"
  logout_uri                 = ""
  name                       = "Node-RED"
  property_mappings          = [authentik_property_mapping_provider_scope.oidc_openid.id, authentik_property_mapping_provider_scope.oidc_email.id, authentik_property_mapping_provider_scope.oidc_profile.id]
  refresh_token_threshold    = "seconds=0"
  refresh_token_validity     = "days=30"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"
}

resource "authentik_provider_proxy" "uptime_kuma" {
  access_token_validity         = "hours=24"
  authorization_flow            = authentik_flow.provider_consent.uuid
  basic_auth_enabled            = false
  basic_auth_password_attribute = ""
  cookie_domain                 = data.sops_file.secrets.data["value_019"]
  external_host                 = data.sops_file.secrets.data["value_020"]
  intercept_header_auth         = true
  internal_host                 = data.sops_file.secrets.data["value_021"]
  internal_host_ssl_validation  = false
  invalidation_flow             = authentik_flow.provider_logout.uuid
  jwt_federation_providers      = []
  jwt_federation_sources        = []
  mode                          = "forward_domain"
  name                          = "Homelab Forward Auth"
  property_mappings             = [authentik_property_mapping_provider_scope.proxy_outpost.id, authentik_property_mapping_provider_scope.oidc_entitlements.id, authentik_property_mapping_provider_scope.oidc_openid.id, authentik_property_mapping_provider_scope.oidc_email.id, authentik_property_mapping_provider_scope.oidc_profile.id]
  refresh_token_validity        = "days=30"
  skip_path_regex               = ""
}
