# Project Infrastructure and CI/CD Pipeline

This repository contains the Terraform code and Azure Pipelines configuration for deploying the project's infrastructure on Microsoft Azure.

## Overview

The goal of this project was to establish a robust and scalable infrastructure foundation using Infrastructure as Code (IaC) principles and automate its deployment through a CI/CD pipeline. We leveraged Terraform to define the cloud resources and Azure Pipelines to manage the deployment lifecycle.

The infrastructure primarily consists of:

1.  **Azure Kubernetes Service (AKS):** A managed Kubernetes service for orchestrating containerized applications.
2.  **Azure Container Registry (ACR):** A private registry for storing and managing container images.
3.  **Azure Cache for Redis:** A managed Redis instance for caching and session management, enhancing application performance.

These services are deployed within a secure network environment. See the `archi-diagram.jpg` for a visual representation.

## Infrastructure Details

The infrastructure is defined using Terraform and organized into reusable modules for better maintainability and scalability.

*   **Core Resources (`main.tf`):**
    *   **Resource Group:** A logical container holding all related resources for the project.
    *   **Virtual Network (VNet):** Provides a private network space in Azure.
    *   **Subnets:** Segments the VNet, including a dedicated subnet for AKS (`aks-subnet`).
    *   **Network Security Group (NSG):** Associated with the AKS subnet to control inbound/outbound traffic (rules can be further defined as needed).
    *   **Private DNS Zone & Endpoint for Redis:** Ensures that the Redis cache is accessed securely over a private connection from within the VNet, implementing the **Private Link pattern**.
    *   **Random Pet Suffix:** Used to ensure unique naming for resources across deployments.

*   **Modules:**
    *   **AKS (`modules/aks`):** Provisions the AKS cluster with system-assigned managed identity and configures the default node pool within the designated subnet.
    *   **ACR (`modules/acr`):** Creates the Azure Container Registry. An `AcrPull` role assignment is configured in `main.tf` to grant the AKS cluster's managed identity permission to pull images from this registry, following the **least privilege principle**.
    *   **Redis (`modules/redis`):** Sets up the Azure Cache for Redis instance.

*   **Cloud Design Patterns Implemented:**
    *   **Infrastructure as Code (IaC):** Using Terraform to define and manage infrastructure declaratively.
    *   **Modular Design:** Breaking down infrastructure into reusable Terraform modules (AKS, ACR, Redis).
    *   **Private Link:** Securing access to the Redis cache via Azure Private Endpoint and Private DNS Zone.
    *   **Least Privilege:** Granting only necessary permissions (e.g., `AcrPull` for AKS to ACR).
    *   **Environment Isolation:** Using separate Terraform state files (`.tfstate`) and variable groups per environment (`dev`, `prod`) within the pipeline.

## Prerequisites

Before running deployments (pipeline or local), ensure you have:

* Terraform v1.x installed and on your PATH (https://www.terraform.io/downloads).
* Azure CLI installed and authenticated (`az login`).
* kubectl installed (compatible with AKS version).
* Helm CLI installed (for ingress-nginx installation).

## Configure Terraform Backend

Update **backend.tf** with your Azure Storage details for state locking and sharing:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name   = "<state-rg>"
    storage_account_name  = "<state-storage>"
    container_name        = "<state-container>"
    key                   = "<project>.tfstate"
  }
}
```
Ensure the storage account and container exist before running `terraform init`.

## Deployment Options

You can deploy via Azure Pipelines or locally using Terraform and the provided script.

### 1. Azure Pipelines

1. Create Variable Groups in Azure DevOps Library: `terraform-variables-dev` and `terraform-variables-prod`, containing:
   * `servicePrincipalId`, `servicePrincipalKey`, `tenantId`, `subscriptionId`
   * `sshPublicKey` (public key for AKS nodes)
   * `resourcePrefix` (e.g., `myproj`)
   * **Backend storage variables**: `backendRg`, `backendAccount`, `backendContainer`, `backendKey`
2. Configure an Azure Resource Manager service connection using the Service Principal.
3. Verify `azure-pipelines.yml` references the correct variable groups and service connection name.
4. Push to `dev` branch to trigger the **Validate** stage; push or merge to `main` to run **Validate**, **Apply**, and **Verify**.

Logs and plan artifacts are available in the pipeline run details.

### 2. Local Deployment

1. Clone this repo and navigate to the `infra` folder.
2. `az login` to your Azure subscription.
3. Configure `backend.tf` as above.
4. Run:
   ```bash
   terraform init
   terraform plan -out plan.tfplan
   terraform apply plan.tfplan
   ```
5. After Terraform completes, deploy Kubernetes resources:
   ```bash
   chmod +x setup-aks.sh
   ./setup-aks.sh
   ```
   This script:
   * Retrieves output values (resource group, AKS name, ACR server).
   * Configures `kubectl` credentials.
   * Applies namespace and app manifests in `kubernetes/`.
   * Installs/updates ingress-nginx via Helm.

## Folder Structure

```
infra/
├── archi-diagram.jpg       # Architecture diagram
├── backend.tf              # Terraform backend configuration
├── azure-pipelines.yml     # CI/CD pipeline definition
├── main.tf                 # Core Terraform resources
├── modules/                # Reusable Terraform modules
│   ├── aks/
│   ├── acr/
│   └── redis/
├── providers.tf            # Azure and Terraform providers
├── setup-aks.sh            # AKS post-deploy bootstrap script
├── variables.tf            # Input variable definitions
└── outputs.tf              # Terraform outputs
```

## CI/CD Pipeline (`azure-pipelines.yml`)

The deployment process is automated using Azure Pipelines, triggered by pushes to the `dev` and `main` branches.

*   **Triggers:** The pipeline runs automatically when changes are pushed to `.tf` files or the `azure-pipelines.yml` file in the `dev` or `main` branches.
*   **Environments:** The pipeline dynamically determines the environment (`dev` or `prod`) based on the source branch (`Build.SourceBranchName`). This controls variable group selection (e.g., `terraform-variables-dev`) and the Terraform state file key.
*   **Stages:**
    1.  **Validate:**
        *   Installs Terraform.
        *   Sets up the SSH public key required by AKS (retrieved from secure variable group).
        *   Initializes Terraform, configuring the Azure backend for state storage.
        *   Runs `terraform validate` to check syntax.
        *   Runs `terraform plan` to preview changes and saves the plan file as an artifact.
    2.  **Apply:**
        *   *Condition:* Runs only on the `main` branch after `Validate` succeeds and it's not a Pull Request build.
        *   Downloads the plan artifact from the `Validate` stage.
        *   Initializes Terraform again.
        *   Runs `terraform apply` using the downloaded plan file to deploy/update the infrastructure.
    3.  **Verify:**
        *   *Condition:* Runs only after `Apply` succeeds.
        *   Initializes Terraform to access state outputs.
        *   Uses Azure CLI (authenticating via Service Principal from the variable group) to:
            *   Retrieve the AKS cluster name and resource group name from Terraform outputs.
            *   Check the `provisioningState` of the AKS cluster.
            *   Fails the pipeline if the state is not `Succeeded`.
    4.  **Destroy (Commented Out):**
        *   A commented-out stage demonstrates how infrastructure destruction could be automated. **Use with extreme caution.** It requires `terraform destroy -auto-approve`. Manual approval or specific triggers are highly recommended for destroy operations.

*   **Key Tasks:**
    *   `TerraformInstaller`: Installs a specific Terraform version.
    *   `TerraformTaskV4`: Executes Terraform commands (init, validate, plan, apply, output).
    *   `Bash`: Used for setting up SSH keys, syncing agent time, and running Azure CLI verification scripts.
    *   `PublishPipelineArtifact`/`DownloadPipelineArtifact`: Manages the Terraform plan file between stages.

*   **Security:** Secrets (Service Principal credentials, SSH key, etc.) are stored securely in Azure DevOps Variable Groups (`terraform-variables-dev`, `terraform-variables-prod`).

## How to Run the Project

Deployment is primarily managed through the Azure Pipeline.

**Prerequisites:**

1.  **Azure Subscription:** Access to an Azure subscription.
2.  **Azure DevOps Project:** An Azure DevOps project with Azure Pipelines enabled.
3.  **Service Principal:** An Azure Service Principal with sufficient permissions (e.g., Contributor) on the subscription or target resource group scope.
4.  **Azure Storage Account:** For storing the Terraform state file (details configured in the pipeline's `backendAzureRm` settings).
5.  **Variable Groups:** Create `terraform-variables-dev` and `terraform-variables-prod` variable groups in Azure DevOps Library, containing necessary secrets:
    *   `servicePrincipalId`
    *   `servicePrincipalKey`
    *   `tenantId`
    *   `subscriptionId`
    *   `sshPublicKey` (The public key content for AKS node access)
    *   `resourcePrefix` (A base prefix for resource naming, e.g., `myproj`)
6.  **Azure Service Connection:** Configure an Azure Resource Manager service connection in Azure DevOps using the Service Principal created above. Name it `Azure-Service-Connection` (or update the pipeline YAML if using a different name).

**Deployment Steps:**

1.  **Clone the Repository:** Clone this repository to your Azure DevOps project.
2.  **Configure Pipeline:** Ensure the `azure-pipelines.yml` file points to the correct Service Connection name and Variable Groups. Verify the backend storage details (`backendAzureRmResourceGroupName`, `backendAzureRmStorageAccountName`, `backendAzureRmContainerName`).
3.  **Push Changes:**
    *   Pushing changes (to `.tf` files or the pipeline file) to the `dev` branch will trigger the `Validate` stage for the `dev` environment.
    *   Pushing or merging changes to the `main` branch will trigger the `Validate`, `Apply`, and `Verify` stages for the `prod` environment.

The pipeline will handle the Terraform initialization, planning, and application process automatically based on the branch pushed to. Monitor the pipeline runs in Azure DevOps for status and logs.
