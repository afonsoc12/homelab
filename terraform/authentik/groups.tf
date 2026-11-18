# Manage access rules here, but leave user membership to the Authentik UI.
# The built-in superuser group is managed separately.
resource "authentik_group" "access" {
  for_each     = toset(["g1", "g2", "g3"])
  name         = data.sops_file.secrets.data["group_${substr(each.key, 1, 1)}"]
  is_superuser = false
  parents      = []
  roles        = []

  lifecycle {
    ignore_changes = [users]
  }
}

# Preserve the existing Mealie audience while closing unrestricted SSO access.
resource "authentik_policy_binding" "access_mealie" {
  for_each = toset(["g1", "g2"])
  target   = authentik_application.mealie.uuid
  group = {
    g1 = authentik_group.access["g1"].id
    g2 = authentik_group.access["g2"].id
  }[each.key]
  order          = index(["g1", "g2"], each.key)
  enabled        = true
  failure_result = false
}

resource "authentik_policy_binding" "access_grafana" {
  target         = authentik_application.grafana.uuid
  group          = authentik_group.access["g1"].id
  order          = 0
  enabled        = true
  failure_result = false
}

# New household access is a Viewer role in Grafana, separate from the admin group.
resource "authentik_policy_binding" "access_grafana_household" {
  target         = authentik_application.grafana.uuid
  group          = authentik_group.access["g2"].id
  order          = 1
  enabled        = true
  failure_result = false
}

# One membership check allows either cohort alongside mandatory app policies.
resource "authentik_policy_expression" "group_access" {
  name       = data.sops_file.secrets.data["group_policy_name"]
  expression = data.sops_file.secrets.data["group_policy_expression"]
}
