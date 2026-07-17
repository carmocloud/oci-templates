data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# --- OKE Kubernetes Cluster ---

resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.oke_vcn.id
  type               = "BASIC" # Always Free Tier eligible (control plane is free)

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_api_subnet.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.oke_lb_subnet.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# --- Worker Node Pool ---

resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "${var.cluster_name}-nodepool"
  node_shape         = var.node_shape

  # Custom config for flexible shape (e.g. Ampere A1 ARM CPU)
  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory
  }

  # Configures placement in the availability domain and subnet
  node_config_details {
    size = var.node_pool_size
    
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_nodes_subnet.id
    }
  }

  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }

  # SSH Key to access worker nodes
  ssh_public_key = var.ssh_public_key
}
