resource "authentik_policy_binding" "access_argo_cd_household" {
  target         = authentik_application.argo_cd.uuid
  group          = authentik_group.access["g2"].id
  order          = 1
  enabled        = true
  failure_result = false
}
