resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn-20230526-1915"
  dns_label      = "vcn05261919"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Internet Gateway vcn-20230526-1915"
}

resource "oci_core_default_route_table" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id
  display_name               = "Default Route Table for vcn-20230526-1915"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_default_security_list" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "Default Security List for vcn-20230526-1915"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol  = "1"
    source    = "0.0.0.0/0"
    stateless = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol  = "1"
    source    = "10.0.0.0/16"
    stateless = false
    icmp_options {
      type = 3
    }
  }

  ingress_security_rules {
    description = "Tailscale"
    protocol    = "17"
    source      = "0.0.0.0/0"
    stateless   = false
    udp_options {
      min = 41641
      max = 41641
    }
  }

  ingress_security_rules {
    description = "Plex Relay"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    tcp_options {
      min = 32400
      max = 32400
    }
  }
}

resource "oci_core_default_dhcp_options" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_dhcp_options_id
  domain_name_type           = "CUSTOM_DOMAIN"

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["vcn05261919.oraclevcn.com"]
  }
}

resource "oci_core_subnet" "main" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.0.0/24"
  display_name      = "subnet-20230526-1915"
  dns_label         = "subnet05261919"
  route_table_id    = oci_core_vcn.main.default_route_table_id
  security_list_ids = [oci_core_vcn.main.default_security_list_id]
  dhcp_options_id   = oci_core_vcn.main.default_dhcp_options_id
}
