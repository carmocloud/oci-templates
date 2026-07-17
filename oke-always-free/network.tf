resource "oci_core_vcn" "oke_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-vcn"
  dns_label      = "okevcn"
}

# --- Gateways ---

resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-ig"
  vcn_id         = oci_core_vcn.oke_vcn.id
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-nat"
  vcn_id         = oci_core_vcn.oke_vcn.id
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "sg" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-sg"
  vcn_id         = oci_core_vcn.oke_vcn.id
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

# --- Route Tables ---

resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.cluster_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.cluster_name}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg.id
  }
}

# --- Security Lists ---

# 1. API Endpoint Security List
resource "oci_core_security_list" "api_endpoint_sec_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.cluster_name}-api-sec"

  # Egress: Allow API endpoint to talk to worker nodes
  egress_security_rules {
    destination      = "10.0.10.0/24" # Private worker subnet
    protocol         = "6"            # TCP
    destination_type = "CIDR_BLOCK"
  }

  # Ingress: Allow Kubernetes API traffic (port 6443) from anywhere (or change to your IP)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Ingress: Allow worker nodes to reach Kubernetes API (port 6443)
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.10.0/24" # Worker nodes subnet
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Ingress: Allow worker nodes to reach OKE service (port 12201)
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.10.0/24" # Worker nodes subnet
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 12201
      max = 12201
    }
  }

  # Ingress: ICMP traffic from worker nodes
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# 2. Worker Nodes Security List
resource "oci_core_security_list" "worker_sec_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.cluster_name}-worker-sec"

  # Egress: Allow worker nodes to reach anywhere (via NAT)
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
  }

  # Egress: Allow worker nodes to reach Oracle Services Network via Service Gateway
  egress_security_rules {
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "all"
  }

  # Ingress: Allow intra-subnet traffic (K8s pod networking)
  ingress_security_rules {
    protocol    = "all"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
  }

  # Ingress: Allow Kubernetes Control Plane to communicate with Kubelet (port 10250)
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.0.0/28" # API Endpoint subnet
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  # Ingress: Allow Kubernetes Control Plane to communicate on port 12201
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.0.0/28" # API Endpoint subnet
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 12201
      max = 12201
    }
  }

  # Ingress: ICMP traffic from API Endpoint subnet
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Ingress: Allow SSH (port 22)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0" # Change this to restrict SSH access
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# 3. Load Balancer Security List
resource "oci_core_security_list" "lb_sec_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.cluster_name}-lb-sec"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

# --- Subnets ---

# 1. API Endpoint Subnet (Public)
resource "oci_core_subnet" "oke_api_subnet" {
  cidr_block                 = "10.0.0.0/28"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  display_name               = "${var.cluster_name}-api-subnet"
  dns_label                  = "okeapi"
  route_table_id             = oci_core_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.api_endpoint_sec_list.id]
  prohibit_public_ip_on_vnic = false
}

# 2. Worker Nodes Subnet (Private)
resource "oci_core_subnet" "oke_nodes_subnet" {
  cidr_block                 = "10.0.10.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  display_name               = "${var.cluster_name}-nodes-subnet"
  dns_label                  = "okenodes"
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.worker_sec_list.id]
  prohibit_public_ip_on_vnic = true
}

# 3. Load Balancer Subnet (Public)
resource "oci_core_subnet" "oke_lb_subnet" {
  cidr_block                 = "10.0.20.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  display_name               = "${var.cluster_name}-lb-subnet"
  dns_label                  = "okelb"
  route_table_id             = oci_core_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.lb_sec_list.id]
  prohibit_public_ip_on_vnic = false
}
