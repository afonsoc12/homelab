data "sops_file" "homelab_user_mappings" {
  source_file = "homelab_user_mappings.sops.yaml"
  input_type  = "yaml"
}

locals {
  homelab_user_mappings = yamldecode(data.sops_file.homelab_user_mappings.raw)
}
