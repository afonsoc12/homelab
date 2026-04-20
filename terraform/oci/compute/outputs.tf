output "instance_id" {
  value = oci_core_instance.k3s_oci_m3.id
}

output "public_ip" {
  value = oci_core_instance.k3s_oci_m3.public_ip
}

output "private_ip" {
  value = oci_core_instance.k3s_oci_m3.private_ip
}

output "boot_volume_id" {
  value = oci_core_boot_volume.k3s_oci_m3.id
}
