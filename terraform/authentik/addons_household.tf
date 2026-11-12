resource "authentik_policy_binding" "access_argo_cd_household" {
  target         = authentik_application.argo_cd.uuid
  user           = tonumber(data.sops_file.secrets.data["argo_cd.oidc_household_user_id"])
  order          = 1
  enabled        = true
  failure_result = false
}
