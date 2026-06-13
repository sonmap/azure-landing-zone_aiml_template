# Azure AI/ML Landing Zone Terraform Template

This repository is a Terraform version of the Azure AI/ML Landing Zone pattern.

The original reference is Microsoft Azure's Bicep implementation:

https://github.com/Azure/bicep-ptn-aiml-landing-zone

I used that Bicep landing zone as the design reference and prepared a Terraform-based implementation for testing and reuse. This is not a one-to-one mechanical conversion of every Bicep line. The original project is built around Azure Verified Modules, so the practical Terraform version also follows the AVM-style Terraform pattern and keeps the same main landing zone idea.

The main goal of this repo is simple:

- deploy an AI/ML landing zone with Terraform
- keep the structure close to the Azure reference pattern
- make the expensive optional parts disabled by default
- leave enough detail so the next person can understand what will be created

## Architecture Diagrams

The diagrams below are placeholders. Replace the image files under `docs/images/` with the final architecture diagrams before publishing.

### 1. Overall Landing Zone

![Overall Landing Zone](docs/images/architecture-01-overall.png)

### 2. Network Layout

![Network Layout](docs/images/architecture-02-network.png)

### 3. AI and Data Services

![AI and Data Services](docs/images/architecture-03-ai-data-services.png)

### 4. Cost-Controlled Components

![Cost-Controlled Components](docs/images/architecture-04-cost-control.png)

## What This Deploys

The main working example is:

```bash
examples/standalone
```

This example creates a standalone AI/ML landing zone. It does not depend on an existing hub network or enterprise landing zone.

The configuration includes:

- Resource group
- Virtual network
- Subnets for AI Foundry, private endpoints, container apps, APIM, application gateway, bastion, firewall, jump box, and build workloads
- Network security group
- Route table
- Private DNS zones
- Private DNS zone links
- Private endpoints
- Log Analytics workspace
- Azure AI Foundry / AI Services
- Azure AI Foundry project wiring
- Azure AI Search
- Cosmos DB
- Storage accounts
- Key Vaults
- Container Registry
- Container Apps managed environment
- App Configuration
- Bing grounding account

Some subnet names remain even when the related service is disabled. For example, `AzureFirewallSubnet` and `AzureBastionSubnet` can still exist as subnet definitions, but the actual Azure Firewall and Azure Bastion services are not deployed.

## Expensive Components Disabled

Some Azure services are useful in a production landing zone, but they can create noticeable cost very quickly during a test.

For that reason, the following components are explicitly set to `false` in the standalone example:

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

Also, because Azure Firewall is disabled, this setting is enabled:

```hcl
use_internet_routing = true
```

Without this, the route table can try to point default traffic to a firewall private IP that does not exist.

Disabled by default:

- Azure Firewall
- Azure Bastion
- Application Gateway / WAF
- API Management
- Jump VM
- Build VM

These are the main items I did not want to create by accident during a test run.

## Important Cost Note

This is not a zero-cost deployment.

Even with the expensive optional components disabled, the following services can still create cost:

- Azure AI Foundry / AI Services
- Azure AI Search
- Cosmos DB
- Storage Account
- Key Vault
- Container Registry
- Container Apps Environment
- Private Endpoints
- Log Analytics
- App Configuration
- Bing Grounding

Before running `terraform apply`, check the plan carefully.

```bash
terraform plan
```

If this is only for a quick test, destroy it as soon as the test is finished.

```bash
terraform destroy
```

## Repository Layout

Main files and folders:

```text
.
├── main.tf
├── main.networking.tf
├── main.foundry.tf
├── main.genai_services.tf
├── main.compute.tf
├── main.apim.tf
├── variables.tf
├── variables.networking.tf
├── variables.foundry.tf
├── variables.genai_services.tf
├── outputs.tf
├── modules/
└── examples/
    └── standalone/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        ├── plan.sh
        ├── apply.sh
        └── APPLY.md
```

The recommended starting point is:

```bash
examples/standalone
```

## Standalone Example

The standalone example is prepared for direct testing.

It sets:

```hcl
flag_platform_landing_zone = false
use_internet_routing       = true
```

This means the deployment is self-contained. It creates its own VNet and supporting network resources.

The location is currently:

```hcl
locals {
  location = "australiaeast"
}
```

Change this before deployment if needed.

## How To Run

Login to Azure first:

```bash
az login
az account set --subscription <subscription-id>
```

Then run:

```bash
cd examples/standalone
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

There are helper scripts as well:

```bash
./plan.sh
./apply.sh
```

The scripts do not hide Terraform. They just run the normal init, validate, plan, and apply flow.

## Cleanup

Use Terraform destroy first:

```bash
cd examples/standalone
terraform destroy
```

If a test deployment is interrupted and some resources remain, check the resource group in Azure Portal or with Azure CLI.

Example:

```bash
az resource list -g <resource-group-name> -o table
```

If the resource group only contains test resources and Terraform cleanup is stuck, delete the resource group:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## Current Design Choices

This template is intentionally conservative for cost.

It keeps the AI/ML landing zone shape, but does not create every production network component by default.

The disabled items can be turned back on later when needed:

- enable Azure Firewall when controlled outbound routing is required
- enable Bastion when private VM access is required
- enable Application Gateway when public ingress is required
- enable API Management when API publishing or gateway policy is required
- enable Jump VM or Build VM only when there is a clear operational need

## Notes

This repo is mainly for practical Terraform deployment work. It is not meant to replace the original Microsoft Bicep project.

If you need the original Bicep implementation, use:

https://github.com/Azure/bicep-ptn-aiml-landing-zone

If you use this Terraform version, always check the generated plan and Azure Cost Management after testing.
