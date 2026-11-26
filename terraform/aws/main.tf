terraform {
  required_version = "1.17.2"
  backend "s3" {
    key                         = "homelab/aws"
    encrypt                     = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
  required_providers {
    restful = {
      source  = "magodo/restful"
      version = "0.26.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "= 2.8.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.74.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "= 1.4.1"
    }
  }
}

variable "alexa_session" {
  type = object({
    access_token = string
    etags        = map(string)
  })
  sensitive = true
  ephemeral = true
  validation {
    condition     = alltrue([for key in ["home_assistant", "music_assistant", "account_linking"] : try(length(var.alexa_session.etags[key]) > 0, false)])
    error_message = "Supply current ETags for all three Alexa resources."
  }
}
data "sops_file" "settings" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}
locals {
  settings = jsondecode(data.sops_file.settings.data["settings"])
  skills   = jsondecode(data.sops_file.settings.data["skills"])
}
provider "sops" {}
provider "aws" {
  region     = local.settings.region
  access_key = data.sops_file.settings.data["access_key_id"]
  secret_key = data.sops_file.settings.data["secret_access_key"]
}
provider "restful" {
  alias    = "home_assistant"
  base_url = local.skills.api_uri
  security = { http = { token = { token = var.alexa_session.access_token } } }
  header   = { "If-Match" = lookup(var.alexa_session.etags, "home_assistant", "") }
}

provider "restful" {
  alias    = "music_assistant"
  base_url = local.skills.api_uri
  security = { http = { token = { token = var.alexa_session.access_token } } }
  header   = { "If-Match" = lookup(var.alexa_session.etags, "music_assistant", "") }
}

provider "restful" {
  alias    = "account_linking"
  base_url = local.skills.api_uri
  security = { http = { token = { token = var.alexa_session.access_token } } }
  header   = { "If-Match" = lookup(var.alexa_session.etags, "account_linking", "") }
}
module "home_assistant" {
  source   = "./home-assistant"
  settings = local.settings
}
module "alexa" {
  source   = "./alexa"
  settings = local.skills
  providers = {
    restful.home_assistant  = restful.home_assistant
    restful.music_assistant = restful.music_assistant
    restful.account_linking = restful.account_linking
  }
}
module "iam" {
  source        = "./iam"
  service_roles = local.settings.service_roles
}
