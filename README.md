# Azure AI/ML Landing Zone Terraform Template

This repository contains a Terraform-based version of the Azure AI/ML Landing Zone pattern.

The original reference is Microsoft's Bicep implementation:

https://github.com/Azure/bicep-ptn-aiml-landing-zone

I used the Bicep project as the design reference and rebuilt the deployment flow in Terraform. This is not a line-by-line conversion of every Bicep file. The original project is based on Azure Verified Modules and a modular landing zone layout, so this repository keeps the same general structure and implements it with Terraform modules and examples.

The purpose of this repository is practical:

- keep the Azure AI/ML Landing Zone pattern available in Terraform
- provide a standalone example that can be tested without an existing hub landing zone
- disable several expensive optional services by default
- document what will be deployed before someone runs `terraform apply`
- make it easier to review cost and cleanup after testing

## Source and Conversion Notes

The source pattern is:

```text
Azure/bicep-ptn-aiml-landing-zone
```

This Terraform version follows the same intent:

- AI/ML workload landing zone
- private network layout
- private endpoints
- private DNS zones
- AI Foundry and dependent data services
- observability through Log Analytics
- optional ingress, firewall, bastion, and VM support

The conversion was done at the architecture and module level. In other words, the goal was to reproduce the landing zone behavior in Terraform, not to translate every Bicep expression into Terraform syntax.

## Architecture Diagrams

The diagrams below are placeholders. Replace the image files under `docs/images/` with the final diagrams.

### 1. Overall Landing Zone

![Overall Landing Zone](docs/images/architecture-01-overall.png)

### 2. Network Layout

![Network Layout](docs/images/architecture-02-network.png)

### 3. AI and Data Services

![AI and Data Services](docs/images/architecture-03-ai-data-services.png)

### 4. Cost-Controlled Components

![Cost-Controlled Components](docs/images/architecture-04-cost-control.png)

## Recommended Starting Point

Use the standalone example first:

```bash
examples/standalone
```

This example creates its own resource group, virtual network, subnets, private DNS zones, private endpoints, AI services, and supporting resources.

It does not require an existing Azure Landing Zone hub, Azure Firewall, ExpressRoute, or Bastion host.

## High-Level Deployment Shape

```text
Resource Group
  |
  +-- Virtual Network
  |     +-- AI Foundry subnet
  |     +-- Private endpoint subnet
  |     +-- Container Apps environment subnet
  |     +-- APIM subnet
  |     +-- Application Gateway subnet
  |     +-- Azure Bastion subnet
  |     +-- Azure Firewall subnet
  |     +-- Jumpbox subnet
  |     +-- DevOps build subnet
  |
  +-- Network Security Group
  +-- Route Table
  +-- Private DNS Zones
  +-- Private DNS Zone Links
  +-- Private Endpoints
  |
  +-- Azure AI Foundry / AI Services
  +-- Azure AI Search
  +-- Cosmos DB
  +-- Storage Accounts
  +-- Key Vaults
  +-- Container Registry
  +-- Container Apps Environment
  +-- App Configuration
  +-- Log Analytics Workspace
```

Some subnets are still created even when the service that normally uses them is disabled. For example, `AzureFirewallSubnet` may exist as a subnet, but the Azure Firewall resource itself is not deployed when `firewall_definition.deploy = false`.

## Main Components

| Area | Terraform configuration | What it is for |
| --- | --- | --- |
| Resource group | `resource_group_name` | Main container for the deployment |
| Network | `vnet_definition` | VNet, address space, and workload subnets |
| Routing | `use_internet_routing` | Uses direct internet routing when Azure Firewall is disabled |
| NSG | `nsgs_definition` | Basic subnet traffic control |
| Private DNS | `private_dns_zones` | Name resolution for private endpoints |
| AI Foundry | `ai_foundry_definition` | AI Foundry account, project, model deployment, and connections |
| AI Search | `ai_search_definition`, `ks_ai_search_definition` | Search service used by AI workloads |
| Cosmos DB | `cosmosdb_definition`, `genai_cosmosdb_definition` | Data storage for AI and application services |
| Storage | `storage_account_definition`, `genai_storage_account_definition` | Blob/data storage |
| Key Vault | `key_vault_definition`, `genai_key_vault_definition` | Secrets and service integration |
| Container Registry | `genai_container_registry_definition` | Container image registry |
| Container Apps | `container_app_environment_definition` | Managed environment for app workloads |
| Observability | Log Analytics settings | Central logging and diagnostic target |

## Expensive Components Disabled by Default

Some services are useful in a production landing zone, but they are not always needed for a test deployment. They can also create cost quickly.

For this reason, the standalone example explicitly disables these components:

```hcl
apim_definition = {
  deploy = false
}

app_gateway_definition = {
  deploy = false
}

bastion_definition = {
  deploy = false
}

firewall_definition = {
  deploy = false
}

buildvm_definition = {
  deploy = false
}

jumpvm_definition = {
  deploy = false
}
```

Disabled by default:

| Component | Why it is disabled |
| --- | --- |
| Azure Firewall | High baseline cost, not required for a simple test |
| Azure Bastion | Useful for private VM access, but not needed when no VM is deployed |
| Application Gateway / WAF | Only needed when public ingress is required |
| API Management | Useful for API gateway scenarios, but expensive for a basic test |
| Jump VM | Not required for this template's normal Terraform run |
| Build VM | Not required unless a build agent VM is part of the design |

Because Azure Firewall is disabled, this setting is also used:

```hcl
use_internet_routing = true
```

This avoids a route table pointing to a firewall private IP that does not exist.

## What Still Costs Money

This template is cost-controlled, not free.

The following resources can still create cost:

| Service | Cost note |
| --- | --- |
| Azure AI Foundry / AI Services | Depends on model deployments and usage |
| Azure AI Search | Standard SKU can create steady cost |
| Cosmos DB | Cost depends on throughput/serverless configuration and storage |
| Storage Account | Usually small, but depends on data and transactions |
| Key Vault | Usually small, but still billable |
| Container Registry | SKU matters; Premium is not cheap |
| Container Apps Environment | Can create cost depending on workload profile and usage |
| Private Endpoints | Each private endpoint has hourly/network cost |
| Log Analytics | Ingestion and retention can create cost |
| App Configuration | Standard tier is billable |
| Bing Grounding | Billable service depending on use |

Before applying, review the Terraform plan and check whether the services are needed.

## Repository Layout

```text
.
├── README.md
├── terraform.tf
├── data.tf
├── locals.tf
├── locals.networking.tf
├── locals.foundry.tf
├── main.tf
├── main.networking.tf
├── main.foundry.tf
├── main.genai_services.tf
├── main.compute.tf
├── main.apim.tf
├── main.diagnostics.tf
├── variables.tf
├── variables.networking.tf
├── variables.foundry.tf
├── variables.genai_services.tf
├── variables.compute.tf
├── variables.apim.tf
├── outputs.tf
├── modules/
├── docs/
│   └── images/
└── examples/
    └── standalone/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        ├── plan.sh
        ├── apply.sh
        └── APPLY.md
```

## Standalone Example Details

The standalone example uses:

```hcl
flag_platform_landing_zone = false
use_internet_routing       = true
```

This means:

- the VNet is created by this deployment
- private DNS zones are created by this deployment
- no existing hub network is required
- default routing goes directly to the internet instead of Azure Firewall
- Azure Firewall is not created

The current region is:

```hcl
locals {
  location = "australiaeast"
}
```

Change this before deployment if another region is required.

## Basic Runbook

Login and select the subscription:

```bash
az login
az account set --subscription <subscription-id>
```

Run Terraform:

```bash
cd examples/standalone
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Helper scripts are included:

```bash
./plan.sh
./apply.sh
```

The scripts are only wrappers. They do not change the Terraform behavior.

## Before Apply Checklist

Check these before running `terraform apply`:

- Confirm the Azure subscription is correct.
- Confirm the region in `examples/standalone/main.tf`.
- Confirm the expensive components are still set to `deploy = false`.
- Review the list of resources in `terraform plan`.
- Check whether Azure AI Search, Cosmos DB, Container Registry, and Private Endpoints are really needed.
- Decide whether this is a short test or a longer-running environment.

Useful command:

```bash
terraform plan -out tfplan
terraform show -no-color tfplan
```

## Cleanup

Use Terraform first:

```bash
cd examples/standalone
terraform destroy
```

If Terraform is interrupted, check the resource group:

```bash
az resource list -g <resource-group-name> -o table
```

If the remaining resources are only test resources and cleanup is stuck, delete the resource group:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

Then check again:

```bash
az group show --name <resource-group-name>
```

If the group is gone, Azure CLI will return a not-found error.

## Cost Review

Azure Cost Management is not fully real time. Cost data can be delayed.

For cost review:

```bash
az resource list -g <resource-group-name> -o table
```

In the Azure Portal:

```text
Cost Management > Cost analysis
```

Recommended grouping:

- Group by `Resource group`
- Group by `Service name`
- Group by `Resource`
- Use `Actual cost`
- Use daily granularity for short tests

For short test deployments, deleting the resources is more important than waiting for the cost screen to update.

## Turning Production Components Back On

The disabled components can be enabled later.

Use these only when the design needs them:

| Component | Enable when |
| --- | --- |
| Azure Firewall | You need controlled egress and centralized inspection |
| Azure Bastion | You need browser-based access to private VMs |
| Application Gateway / WAF | You need public HTTP/S ingress and WAF policies |
| API Management | You need API gateway, policy, subscription, or developer portal features |
| Jump VM | You need an operations VM inside the VNet |
| Build VM | You need a self-hosted build agent inside the landing zone |

## Notes

This repository is meant for practical Terraform deployment work. It is not a replacement for the Microsoft Bicep repository.

Use the original Bicep project when you need the official Bicep pattern:

https://github.com/Azure/bicep-ptn-aiml-landing-zone

Use this repository when you need a Terraform version that keeps the same landing zone idea and starts with the expensive optional components disabled.
