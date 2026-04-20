output "vcn_id" {
  value = oci_core_vcn.main.id
}

output "subnet_id" {
  value = oci_core_subnet.main.id
}

output "internet_gateway_id" {
  value = oci_core_internet_gateway.main.id
}
