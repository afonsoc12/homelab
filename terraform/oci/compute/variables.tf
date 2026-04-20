variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID for the primary VNIC"
  type        = string
}
