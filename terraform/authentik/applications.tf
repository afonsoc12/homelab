resource "authentik_application" "argo_cd" {
  backchannel_providers = []
  group                 = "addons"
  meta_description      = ""
  meta_hide             = false
  meta_icon             = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/argo-cd.png"
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
  group                 = "homelab"
  meta_description      = ""
  meta_hide             = false
  meta_icon             = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/mealie.png"
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
  group                 = "automation"
  meta_description      = ""
  meta_hide             = false
  meta_icon             = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/node-red.png"
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
  group                 = "ingress"
  meta_description      = ""
  meta_hide             = true
  meta_icon             = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/uptime-kuma.png"
  meta_launch_url       = ""
  meta_publisher        = ""
  name                  = "Uptime Kuma"
  open_in_new_tab       = false
  policy_engine_mode    = "any"
  protocol_provider     = authentik_provider_proxy.uptime_kuma.id
  slug                  = data.sops_file.secrets.data["value_075"]
  uuid                  = data.sops_file.secrets.data["value_076"]
}

resource "authentik_provider_oauth2" "argo_cd" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "hours=1"
  allowed_redirect_uris      = local.oidc_redirect_uris["argo_cd"]
  authentication_flow        = authentik_flow.login_choice.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_011"]
  client_secret              = data.sops_file.secrets.data["value_012"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "refresh_token"]
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
  refresh_token_validity     = "hours=8"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"

  lifecycle {
    precondition {
      condition     = local.oidc_redirects_safe["argo_cd"]
      error_message = "OIDC callbacks must be nonempty, exact HTTPS URLs without wildcards, query strings or fragments."
    }
  }
}

resource "authentik_provider_oauth2" "mealie" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  allowed_redirect_uris      = local.oidc_redirect_uris["mealie"]
  authentication_flow        = authentik_flow.login_choice.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_014"]
  client_secret              = data.sops_file.secrets.data["value_015"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "refresh_token"]
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
  refresh_token_validity     = "hours=8"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"

  lifecycle {
    precondition {
      condition     = local.oidc_redirects_safe["mealie"]
      error_message = "OIDC callbacks must be nonempty, exact HTTPS URLs without wildcards, query strings or fragments."
    }
  }
}

resource "authentik_provider_oauth2" "node_red" {
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=5"
  allowed_redirect_uris      = local.oidc_redirect_uris["node_red"]
  authentication_flow        = authentik_flow.login_choice.uuid
  authorization_flow         = authentik_flow.provider_authorization.uuid
  client_id                  = data.sops_file.secrets.data["value_017"]
  client_secret              = data.sops_file.secrets.data["value_018"]
  client_type                = "confidential"
  grant_types                = ["authorization_code", "refresh_token"]
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
  refresh_token_validity     = "hours=8"
  signing_key                = authentik_certificate_key_pair.signing.id
  sub_mode                   = "hashed_user_id"

  lifecycle {
    precondition {
      condition     = local.oidc_redirects_safe["node_red"]
      error_message = "OIDC callbacks must be nonempty, exact HTTPS URLs without wildcards, query strings or fragments."
    }
  }
}

resource "authentik_provider_proxy" "uptime_kuma" {
  access_token_validity         = "hours=24"
  authentication_flow           = authentik_flow.login.uuid
  authorization_flow            = authentik_flow.provider_consent.uuid
  basic_auth_enabled            = false
  basic_auth_password_attribute = ""
  cookie_domain                 = "status.${local.apps_domain}"
  external_host                 = "https://status.${local.apps_domain}"
  intercept_header_auth         = false
  internal_host                 = "http://uptime-kuma.monitoring.svc.cluster.local:3001"
  internal_host_ssl_validation  = true
  invalidation_flow             = authentik_flow.provider_logout.uuid
  jwt_federation_providers      = []
  jwt_federation_sources        = []
  mode                          = "proxy"
  name                          = "Uptime Kuma Proxy"
  property_mappings             = [authentik_property_mapping_provider_scope.proxy_outpost.id, authentik_property_mapping_provider_scope.oidc_entitlements.id, authentik_property_mapping_provider_scope.oidc_openid.id, authentik_property_mapping_provider_scope.oidc_email.id, authentik_property_mapping_provider_scope.oidc_profile.id]
  refresh_token_validity        = "days=30"
  skip_path_regex               = ""
}
