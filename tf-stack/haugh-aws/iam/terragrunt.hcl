include {
  path = find_in_parent_folders("terragrunt.hcl")
  }

terraform {
  source = "../../../Terraform_AWS/modules/iam"
  }
