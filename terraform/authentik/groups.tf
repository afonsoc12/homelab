# Manage access rules here, but leave user membership to the Authentik UI.
# Keep the existing Authentik administrator group and its bindings intact.
resource "authentik_group" "access" {
  for_each     = toset(["house", "plex", "external"])
  name         = each.key
  is_superuser = false
  parents      = []
  roles        = []

  lifecycle {
    ignore_changes = [users]
  }
}

data "authentik_group" "mealie" {
  for_each = toset(["mealie_admin", "mealie_user"])
  name     = each.key
}

# Preserve the existing Mealie audience while closing unrestricted SSO access.
resource "authentik_policy_binding" "access_mealie" {
  for_each = toset(["admins", "house", "mealie_admin", "mealie_user"])
  target   = authentik_application.mealie.uuid
  group = {
    admins       = data.sops_file.secrets.data["value_079"]
    house        = authentik_group.access["house"].id
    mealie_admin = data.authentik_group.mealie["mealie_admin"].id
    mealie_user  = data.authentik_group.mealie["mealie_user"].id
  }[each.key]
  order          = index(["admins", "house", "mealie_admin", "mealie_user"], each.key)
  enabled        = true
  failure_result = false
}

resource "authentik_policy_binding" "access_grafana" {
  target         = authentik_application.grafana.uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  enabled        = true
  failure_result = false
}

# New household access is a Viewer role in Grafana, separate from the admin group.
resource "authentik_policy_binding" "access_grafana_household" {
  target         = authentik_application.grafana.uuid
  user           = tonumber(data.sops_file.secrets.data["grafana.oidc_household_user_id"])
  order          = 1
  enabled        = true
  failure_result = false
}
