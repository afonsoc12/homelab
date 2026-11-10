# Keep packaged discovery controls disabled so removed configuration stays removed.
resource "authentik_blueprint" "packaged" {
  for_each = toset(["bootstrap", "login", "brand", "events_transport_rules", "logout", "out_of_box_experience_flow", "password_change_flow", "provider_authorization_flow_explicit_consent", "provider_authorization_flow_implicit_consent", "provider_logout", "rbac_agent_users", "rbac_read_only", "request_flow", "source_authentication_flow", "source_enrollment_flow", "source_pre_authentication_flow", "static_mfa_setup_flow", "totp_mfa_setup_flow", "account_settings", "webauthn_mfa_setup_flow", "prompt_migration", "google_workspace_provider_mappings", "kerberos_source_mappings", "ldap_source_mappings", "microsoft_entra_provider_mappings", "oauth2_provider_scopes", "user_attributes", "proxy_provider_scopes", "rac_provider_mappings", "saml_provider_mappings", "scim_provider_mappings"])

  name    = jsondecode(data.sops_file.secrets.data["value_002"])[each.key].name
  path    = jsondecode(data.sops_file.secrets.data["value_002"])[each.key].path
  context = jsonencode({})
  enabled = each.key == "user_attributes"
}
