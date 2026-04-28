terraform {
  required_version = ">= 1.10"

  backend "s3" {
    # Remaining conf stored in backend.sops.yaml
    key                         = "homelab/adguard"
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
    adguard = {
      source  = "gmichels/adguard"
      version = "~> 1.7"
    }
  }
}
