resource "cloudflare_zero_trust_organization" "homelab" {
  account_id  = data.sops_file.secrets.data["account_id"]
  auth_domain = data.sops_file.authentik.data["cloudflare_access.team_domain"]

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      deny_unmatched_requests,
      deny_unmatched_requests_exempted_zone_names,
      service_token_inactivity,
    ]
  }
}
