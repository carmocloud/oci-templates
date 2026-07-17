# Always Free OKE (Oracle Container Engine for Kubernetes) Template

This Terraform template deploys a fully functioning Kubernetes cluster on Oracle Cloud Infrastructure (OCI) under the **Always Free Tier** limits.

## 🌟 Always Free Tier Resource Coverage
This template is optimized to utilize OCI's Always Free resources:
* **Cluster Control Plane**: Deployed as a `BASIC` cluster type, which has no control plane charge and is Always Free (up to 10 nodes).
* **Worker Nodes**: Uses the `VM.Standard.A1.Flex` shape (Ampere ARM-based), which is Always Free for up to 4 OCPUs and 24 GB of RAM total. By default, this template configures **1 worker node with 2 OCPUs and 12 GB RAM**, leaving resources for other free-tier VMs!

---

## 📂 Template Structure
* `provider.tf`: Configures the OCI Terraform provider.
* `variables.tf`: Input variables for customizing tenancy, shape, and key details.
* `network.tf`: Sets up the VCN, gateways (Internet, NAT, and Service Gateways), public subnets for the API and load balancers, and a private subnet for the worker nodes.
* `oke.tf`: Configures the basic Kubernetes cluster control plane and worker node pool.
* `outputs.tf`: Outputs the cluster ID, node pool ID, and the direct `kubeconfig` download command.

---

## 🚀 How to Deploy

### 1. Locate your OKE Image OCID
Oracle Cloud requires OKE worker nodes to use a specific, OKE-optimized Linux image. 
To find the latest OKE Image OCID for your region:
1. Open the OCI Console.
2. Go to **Developer Services** -> **Kubernetes Clusters (OKE)**.
3. Click **Create Cluster** and look at the Node Pool configuration to find the default image name (usually starts with `Oracle-Linux-8.x...`) and copy its OCID, or use the OCI CLI to list supported options:
   ```bash
   oci ce node-pool-options get --node-pool-option-id all --profile CARMOCLOUD
   ```

### 2. Create `terraform.tfvars`
Create a file named `terraform.tfvars` in this directory and populate your variables:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaa..."
user_ocid        = "ocid1.user.oc1..aaaaaaaa..."
fingerprint      = "9b:8b:43:32:75:a3:17:70:29:b7:fa:53:71:b4:59:1c"
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa..."
ssh_public_key   = "ssh-rsa AAAAB3NzaC1..."
node_image_id    = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa..." # OKE-optimized image OCID
```

### 3. Deploy with Terraform
```bash
terraform init
terraform plan
terraform apply
```

---

## ⚡ Connecting to the Cluster
Once the deployment completes, Terraform will output a dynamic `kubeconfig_command`. Copy and run that command to download the kubeconfig file directly onto your local machine:

```bash
# Example Output Command:
oci ce cluster create-kubeconfig --cluster-id <cluster_ocid> --file $HOME/.kube/config --region sa-saopaulo-1 --token-version 2.0.0 --profile CARMOCLOUD
```

Verify your connection with `kubectl`:
```bash
kubectl get nodes
```
