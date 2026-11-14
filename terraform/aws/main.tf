data "sops_file" "settings" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}
locals {
  settings = jsondecode(data.sops_file.settings.data["settings"])
}
data "sops_file" "credentials" {
  source_file = "terraform-credentials.sops.yaml"
  input_type  = "yaml"
}

provider "sops" {}

provider "aws" {
  region     = local.settings.region
  access_key = data.sops_file.credentials.data["access_key_id"]
  secret_key = data.sops_file.credentials.data["secret_access_key"]
}
module "alexa" {
  source             = "./alexa"
  settings           = local.settings
  package_path       = "${path.module}/.build/function.zip"
  oauth_package_path = "${path.module}/.build/oauth.zip"
}

module "iam" {
  source        = "./iam"
  service_roles = local.settings.service_roles
}
