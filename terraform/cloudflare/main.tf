data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "sops" {}

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["api_token"]
}

module "dns_zone_homelab" {
  source       = "./dns"
  zone_id      = data.sops_file.secrets.data["zones.0.zone_id"]
  records_file = "${path.module}/dns/zone-homelab.sops.yaml"
}

module "dns_zone_personal" {
  source       = "./dns"
  zone_id      = data.sops_file.secrets.data["zones.1.zone_id"]
  records_file = "${path.module}/dns/zone-personal.sops.yaml"
}

module "zone_homelab" {
  source  = "./zone"
  zone_id = data.sops_file.secrets.data["zones.0.zone_id"]

  ssl_mode         = "strict"
  min_tls_version  = "1.2"
  always_use_https = true

  block_bots        = true
  allow_aws         = true
  geo_block_enabled = true
  geo_allowlist     = ["PT", "GB"]
}

module "zone_personal" {
  source  = "./zone"
  zone_id = data.sops_file.secrets.data["zones.1.zone_id"]

  ssl_mode         = "strict"
  min_tls_version  = "1.2"
  always_use_https = true

  block_bots        = true
  allow_aws         = false
  geo_block_enabled = false
}

module "tunnels" {
  source             = "./tunnels"
  account_id         = data.sops_file.secrets.data["account_id"]
  zone_id            = data.sops_file.secrets.data["zones.0.zone_id"]
  domain             = data.sops_file.secrets.data["zones.0.domain"]
  k3s_cluster_secret = data.sops_file.secrets.data["tunnels.k3s_cluster.secret"]
}
