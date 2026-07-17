variable "tenancy_ocid" {
  description = "The OCID of your OCI Tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "region" {
  description = "The OCI Region to deploy into"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "auth_type" {
  description = "The type of authentication to use. Set to 'SecurityToken' for session token authentication (recommended), or leave blank for standard API key authentication."
  type        = string
  default     = "SecurityToken"
}

variable "config_file_profile" {
  description = "The profile name in your ~/.oci/config file to use for authentication"
  type        = string
  default     = "CARMOCLOUD"
}

variable "user_ocid" {
  description = "The OCID of your OCI User (only needed for API key auth)"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "The fingerprint of your API private key (only needed for API key auth)"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "The local path to your OCI API private key (only needed for API key auth)"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "The name of the OKE Kubernetes cluster"
  type        = string
  default     = "carmocloud-alwaysfree-oke"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to deploy"
  type        = string
  default     = "v1.30.1" # Change to active OKE-supported version
}

variable "node_shape" {
  description = "The compute shape for worker nodes (Ampere A1 Flex is Always Free eligible)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  description = "Number of OCPUs for the Always Free Ampere A1 worker nodes"
  type        = number
  default     = 2 # Always Free limit is 4 OCPUs total across all instances
}

variable "node_memory" {
  description = "Memory in GB for the Always Free Ampere A1 worker nodes"
  type        = number
  default     = 12 # Always Free limit is 24 GB total across all instances
}

variable "node_pool_size" {
  description = "Number of worker nodes in the node pool"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key content to install on worker nodes"
  type        = string
}

variable "node_image_id" {
  description = "The OCID of the OKE-compatible operating system image for worker nodes"
  type        = string
  # User must specify the OKE-optimized image OCID for their region and K8s version
}
