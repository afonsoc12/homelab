terraform {
  required_version = ">= 1.10"

  backend "s3" {
    # Remaining conf stored in backend.sops.yaml
    key                         = "homelab/oci"
    encrypt                     = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1"
    }
    oci = {
      source  = "oracle/oci"
      version = "8.12.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

provider "oci" {
  tenancy_ocid = data.sops_file.secrets.data["tenancy_ocid"]
  user_ocid    = data.sops_file.secrets.data["user_ocid"]
  fingerprint  = data.sops_file.secrets.data["fingerprint"]
  private_key  = data.sops_file.secrets.data["private_key"]
  region       = var.region
}
