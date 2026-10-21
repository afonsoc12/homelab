resource "authentik_brand" "homelab" {
  domain           = data.sops_file.secrets.data["value_001"]
  default          = true
  branding_title   = "Homelab SSO"
  branding_logo    = data.sops_file.secrets.data["value_038"]
  branding_favicon = data.sops_file.secrets.data["value_039"]

  flow_authentication = authentik_flow.login.uuid
  flow_invalidation   = authentik_flow.logout.uuid
  flow_recovery       = authentik_flow.recovery.uuid
  flow_user_settings  = authentik_flow.account_settings.uuid

  # authentik is built on PatternFly; these selectors restyle the flow
  # executor (login/recovery/etc.) shell without touching the admin UI.
  # Reuse the documentation palette.
  branding_custom_css = data.sops_file.secrets.data["value_037"]
}
