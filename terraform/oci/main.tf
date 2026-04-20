locals {
  compartment_id = data.sops_file.secrets.data["tenancy_ocid"]
}

module "networking" {
  source = "./networking"

  compartment_id      = local.compartment_id
  availability_domain = var.availability_domain
}

module "compute" {
  source = "./compute"

  compartment_id      = local.compartment_id
  availability_domain = var.availability_domain
  subnet_id           = module.networking.subnet_id
}
