locals {
  oidc_redirect_uris = {
    argo_cd  = jsondecode(data.sops_file.secrets.data["value_010"])
    mealie   = jsondecode(data.sops_file.secrets.data["value_013"])
    node_red = jsondecode(data.sops_file.secrets.data["value_016"])
    grafana  = jsondecode(data.sops_file.secrets.data["grafana_redirect_uris"])
  }
  # Reject unsafe encrypted configuration without printing its values in errors.
  oidc_redirects_safe = { for app, uris in local.oidc_redirect_uris : app => (
    length(uris) > 0 && alltrue([for uri in uris :
      try(uri.matching_mode == "strict" && startswith(uri.url, "https://") && length(regexall("[*?#@[:space:]]", uri.url)) == 0, false)
    ])
  ) }

  # Bind verification to the exact address, never a freely editable Boolean.
  # Native account-linking integrations retain their separate approval ledger.
  oidc_verified_email_expression = <<-PY
    email = request.user.email
    verified = request.user.attributes.get("email_verified_address")
    return {"email": email, "email_verified": bool(email) and verified == email}
  PY
}

# Only clients that already request offline_access receive this mapping.
resource "authentik_property_mapping_provider_scope" "oidc_offline_access" {
  name        = "Homelab - OIDC Offline Access"
  description = "Refresh access for explicitly configured clients"
  scope_name  = "offline_access"
  expression  = "return {}"
}
