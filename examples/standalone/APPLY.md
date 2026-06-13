# Apply Guide

This standalone example is prepared for a lower-cost Terraform apply.

The following high-cost optional components are disabled:

- API Management
- Application Gateway / WAF
- Azure Bastion
- Azure Firewall
- Build VM
- Jump VM

Because Azure Firewall is disabled, `use_internet_routing = true` is set so default routes do not reference a non-existent firewall private IP.

Run:

```bash
cd /home/son/aiml-landing-zone-terraform/examples/standalone
az login
./plan.sh
./apply.sh
```

If the server already has an expired Azure CLI session, run `az login` again before `./plan.sh`.

Even with these components disabled, Azure AI Foundry, model deployments, AI Search, Cosmos DB, Storage, Key Vault, Container Apps, Container Registry, Private Endpoints, and Log Analytics can still create Azure costs.
