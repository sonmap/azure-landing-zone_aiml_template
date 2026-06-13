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

flowchart TB
    EXT["External User / Internet"]

    subgraph SUB["Subscription_sonmap01"]

        %% ===================== AKS DEMO =====================
        subgraph KRC["Korea Central / AKS Demo"]
            subgraph RGNET["RG: rg-aksdemo-net-dev-krc"]
                PIPAPPGW["Public IP<br/>pip-aksdemo-appgw-dev-krc"]
                APPGW["Application Gateway<br/>appgw-aksdemo-dev-krc"]
                HUBVNET["Hub VNet<br/>vnet-aksdemo-hub-dev-krc"]
            end

            subgraph RGWORK["RG: rg-aksdemo-work-dev-krc"]
                WORKVNET["Work VNet<br/>vnet-aksdemo-work-dev-krc"]
                AKS["AKS Cluster<br/>aks-aksdemo-dev-krc"]
                AKSID["Managed Identity<br/>id-aksdemo-aks-dev-krc"]
            end

            subgraph AKSMC["Managed RG:<br/>MC_rg-aksdemo-work-dev-krc_aks-aksdemo-dev-krc_koreacentral"]
                VMSS["VMSS Agent Pool<br/>aks-system-15533062-vmss"]
                AKSNSG["NSG<br/>aks-agentpool-32235780-nsg"]
                LBPUB["Load Balancer<br/>kubernetes"]
                LBINT["Internal Load Balancer<br/>kubernetes-internal"]
                AKSPIP["Public IP<br/>6f2018d8-a80a-40a2-9383-e4db1a4cb7c3"]
                AKSMI["Managed Identities<br/>agentpool / omsagent"]
            end

            subgraph RGMON["RG: rg-aksdemo-mon-dev-krc"]
                AKSLAW["Log Analytics<br/>log-aksdemo-dev-krc"]
                CI["ContainerInsights<br/>ContainerInsights(log-aksdemo-dev-krc)"]
            end

            EXT --> PIPAPPGW --> APPGW --> HUBVNET
            HUBVNET <-->|VNet Peering| WORKVNET
            WORKVNET --> AKS
            AKS --> VMSS
            VMSS --> AKSNSG
            AKS --> LBINT
            AKS -. "외부 서비스 사용 시" .-> LBPUB --> AKSPIP
            AKS --> AKSID
            AKS --> AKSMI
            AKS --> AKSLAW --> CI
        end

        %% ===================== AI LANDING ZONE =====================
        subgraph AUE["Australia East / AI Landing Zone Standalone"]
            subgraph RGAILZ["RG: ai-lz-rg-standalone-hcyak"]
                AILZVNET["VNet<br/>ai-lz-vnet-standalone"]
                AILZNSG["NSG<br/>ai-alz-nsg"]
                RT["Route Table<br/>ai-lz-vnet-standalone-firewall-route-table"]
                FWPIP["Public IP<br/>ai-alz-fw-pip<br/>※ Firewall 본체는 목록에 없음"]

                CAE["Container Apps Environment<br/>ai-alz-container-app-env-6b17"]
                ACR["Container Registry<br/>genaicr6b17"]
                FOUNDRY["Azure AI Foundry<br/>ai-foundry-6b17"]

                SEARCH1["AI Search / Foundry IQ<br/>ai-alz-ks-ai-search-6b17"]
                SEARCH2["AI Search / Foundry IQ<br/>foundry-this-ai-foundry-ai-search-oljtt"]

                COSMOS1["Cosmos DB<br/>genai-cosmosdb-6b17"]
                COSMOS2["Cosmos DB<br/>foundry-this-foundry-cosmosdb-oljtt"]

                STG1["Storage Account<br/>genaisa6b17"]
                STG2["Storage Account<br/>foundrythisfndrysaoljtt"]

                KV1["Key Vault<br/>genai-kv-6b17"]
                KV2["Key Vault<br/>foundry-kv-oljtt"]

                APPCFG["App Configuration<br/>genai-appconfig-6b17"]
                BING["Bing Grounding<br/>ai-alz-ks-bing-grounding-6b17"]
                AILAW["Log Analytics<br/>ai-alz-law"]

                PE["Private Endpoints + NICs<br/>Blob / KV / ACR / AppConfig / Cosmos DB"]
                DNS["Private DNS Zones<br/>Storage / KeyVault / ACR / Cosmos<br/>AI Search / OpenAI / AI Services / AppConfig"]
            end

            subgraph CAMANAGED["Managed RG:<br/>rg-managed-ai-lz-rg-standalone-hcyak"]
                CAPPLB["Load Balancer<br/>capp-svc-lb"]
            end

            AILZVNET --> AILZNSG
            AILZVNET --> RT --> FWPIP
            AILZVNET --> CAE --> CAPPLB
            AILZVNET --> PE
            DNS -. "Private DNS Resolution" .-> PE

            PE --> ACR
            PE --> APPCFG
            PE --> KV1
            PE --> KV2
            PE --> COSMOS1
            PE --> COSMOS2
            PE --> STG1
            PE --> STG2

            CAE --> FOUNDRY
            CAE --> BING
            CAE --> AILAW

            FOUNDRY --> SEARCH1
            FOUNDRY --> SEARCH2
            FOUNDRY --> COSMOS2
            FOUNDRY --> STG2
            FOUNDRY --> KV2
        end
    end

    classDef net fill:#E8F1FF,stroke:#2B6CB0,stroke-width:1px;
    classDef compute fill:#EAF7EA,stroke:#2F855A,stroke-width:1px;
    classDef data fill:#FFF7E6,stroke:#B7791F,stroke-width:1px;
    classDef sec fill:#F3E8FF,stroke:#6B46C1,stroke-width:1px;
    classDef mon fill:#FEECEC,stroke:#C53030,stroke-width:1px;

    class PIPAPPGW,APPGW,HUBVNET,WORKVNET,LBPUB,LBINT,AKSPIP,AILZVNET,RT,FWPIP,CAPPLB net;
    class AKS,VMSS,CAE,FOUNDRY compute;
    class ACR,SEARCH1,SEARCH2,COSMOS1,COSMOS2,STG1,STG2,APPCFG,BING data;
    class AKSID,AKSMI,AKSNSG,AILZNSG,KV1,KV2,PE,DNS sec;
    class AKSLAW,CI,AILAW mon;

### 2. AI Overall Landing Zone 2
<img width="1938" height="1377" alt="image" src="https://github.com/user-attachments/assets/7ff91c80-6309-4651-ab69-163466d0a03d" />

### 2. Private DNS zone simple flow

<img width="2122" height="1182" alt="image" src="https://github.com/user-attachments/assets/4986bd34-6093-4f8f-9dc0-66936145a08d" />


### 3. AI and Data Services Landing Zone detail 1

<img width="2057" height="1370" alt="image" src="https://github.com/user-attachments/assets/1e89160b-a39b-487a-a9df-501994795626" />

### 3. AI and Data Services Landing Zone detail 2
<img width="915" height="1371" alt="image" src="https://github.com/user-attachments/assets/9e6bc5cb-5007-496a-8a86-cc8241e07084" />

### 4. AI and Data Services Landing Zone detail 3
<img width="2048" height="1367" alt="image" src="https://github.com/user-attachments/assets/167527e5-436c-4bd4-8e1b-a37ed8e7685d" />

![Cost-Controlled Components](docs/images/architecture-04-cost-control.png)


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
