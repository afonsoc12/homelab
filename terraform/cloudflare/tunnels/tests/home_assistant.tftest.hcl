mock_provider "cloudflare" {}
variables {
  account_id            = "00000000000000000000000000000000"
  zone_id               = "00000000000000000000000000000000"
  domain                = "example.invalid"
  k3s_cluster_secret    = "test-only"
  spliit_access_emails  = []
  authentik_idp_id      = "test-idp"
  firefly_access_emails = []
  access_team_name      = "test-team"
  owner_access_email    = "owner@example.invalid"
}
run "service_auth_and_route_isolation" {
  command = plan
  assert {
    condition     = cloudflare_zero_trust_access_policy.home_assistant_machine.decision == "non_identity"
    error_message = "Machine access must require service authentication."
  }
  assert {
    condition = (
      cloudflare_zero_trust_tunnel_cloudflared_config.k3s_cluster.config.ingress[0].path == "^/api/alexa/smart_home$" &&
      cloudflare_zero_trust_tunnel_cloudflared_config.k3s_cluster.config.ingress[1].path == "^/auth/token$" &&
      cloudflare_zero_trust_tunnel_cloudflared_config.k3s_cluster.config.ingress[0].origin_request.access.required &&
      cloudflare_zero_trust_tunnel_cloudflared_config.k3s_cluster.config.ingress[1].origin_request.access.required &&
      cloudflare_zero_trust_tunnel_cloudflared_config.k3s_cluster.config.ingress[2].service == "http_status:404"
    )
    error_message = "Only exact command and token routes may reach an origin, with tunnel JWT validation."
  }
}
