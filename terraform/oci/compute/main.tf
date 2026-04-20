resource "oci_core_boot_volume" "k3s_oci_m3" {
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  display_name         = "k3s-oci-m3 (Boot Volume)"
  size_in_gbs          = 200
  vpus_per_gb          = 10
  is_auto_tune_enabled = false

  source_details {
    type = "bootVolume"
    id   = "ocid1.bootvolume.oc1.uk-cardiff-1.abrxoljrh5o7lheovclbbxt7tximrpwxj5wzvxae6ztggg2qnhl5rx5ggpqa"
  }

  lifecycle {
    ignore_changes  = [source_details]
    prevent_destroy = true
  }
}

resource "oci_core_instance" "k3s_oci_m3" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "k3s-oci-m3"
  fault_domain        = "FAULT-DOMAIN-2"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type = "bootVolume"
    source_id   = oci_core_boot_volume.k3s_oci_m3.id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "k3s-oci-m3"
    hostname_label   = "k3s-oci-m3"
    assign_public_ip = true
    private_ip       = "10.0.0.90"
  }

  agent_config {
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }

  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }

  lifecycle {
    prevent_destroy = true
  }
}
