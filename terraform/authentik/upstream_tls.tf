data "sops_file" "kubernetes" {
  source_file = "../../kubernetes/apps/values.sops.yaml"
  input_type  = "yaml"
}
