data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "postgresql" {
  host     = split(":", data.sops_file.secrets.data["host"])[0]
  port     = tonumber(split(":", data.sops_file.secrets.data["host"])[1])
  username = data.sops_file.secrets.data["username"]
  password = data.sops_file.secrets.data["password"]
  sslmode  = "disable"
}
