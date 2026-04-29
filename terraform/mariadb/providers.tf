data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "mysql" {
  endpoint = data.sops_file.secrets.data["endpoint"]
  username = data.sops_file.secrets.data["username"]
  password = data.sops_file.secrets.data["password"]
}
