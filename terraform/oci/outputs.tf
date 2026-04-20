output "instance_id" {
  description = "OCID of the k3s-oci-m3 compute instance"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP of k3s-oci-m3"
  value       = module.compute.public_ip
}

output "instance_private_ip" {
  description = "Private IP of k3s-oci-m3"
  value       = module.compute.private_ip
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.networking.vcn_id
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = module.networking.subnet_id
}
