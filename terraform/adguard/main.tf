data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "sops" {}

provider "adguard" {
  host     = data.sops_file.secrets.data["host"]
  username = data.sops_file.secrets.data["username"]
  password = data.sops_file.secrets.data["password"]
  scheme   = "https"
  timeout  = 60
}
