# Bicep to Terraform Conversion Notes

Source Bicep repository:
https://github.com/Azure/bicep-ptn-aiml-landing-zone

Terraform baseline used:
https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone

This folder is the official Azure Terraform implementation corresponding to the AI/ML Landing Zone pattern. It is not a line-by-line syntactic conversion of Bicep files. The Bicep template is AVM-module based, so the practical Terraform conversion is to use the matching AVM Terraform pattern module and its deployable examples.

Start with one of the example folders:

- `examples/default`
- `examples/basic`

Typical workflow:

```bash
cd /home/son/aiml-landing-zone-terraform/examples/default
terraform init
terraform plan
terraform apply
```

Set Azure credentials before running Terraform, for example with `az login` or service-principal environment variables.
