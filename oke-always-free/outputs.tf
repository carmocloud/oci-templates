output "cluster_id" {
  description = "The OCID of the OKE Kubernetes cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "node_pool_id" {
  description = "The OCID of the worker node pool"
  value       = oci_containerengine_node_pool.oke_node_pool.id
}

output "kubeconfig_command" {
  description = "Command to download and configure kubeconfig for this cluster"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --profile ${var.private_key_path == "~/.oci/sessions/CARMOCLOUD/oci_api_key.pem" ? "CARMOCLOUD" : "DEFAULT"}"
}
