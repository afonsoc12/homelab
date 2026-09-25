data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "sops" {}

provider "authentik" {
  url   = data.sops_file.secrets.data["url"]
  token = data.sops_file.secrets.data["token"]
}
