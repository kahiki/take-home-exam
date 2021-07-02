# Use locals to create inputs that modules will consume. defining in inputs reduces the need for a common vars that would need to be included per hcl file.
locals {
  # Used to resolve the bucket name in the event of doing a terragrunt apply/destroy all in the uat folder, or doing a
  # terragrunt apply in a resource folder
  customer    = "${element(reverse(split("/", "${get_terragrunt_dir()}")), 2)}"
  environment = "${basename(get_parent_terragrunt_dir())}"
  region      = "us-east-1"
  users       = ["prod-ci-user"]
  group-name  = "prod-ci-group"
  role-name   = "prod-ci-role"
  policy-name = "prod-ci-policy"
  allowed_roles = ["prod-ci-role"]
  trusted_role_arn = ["arn:aws:iam::218669829142:root"]
}

# Terraform command properties, here we are telling terraform to always use common tf vars, and then to look for
# optional variable files if they are present
terraform {
  extra_arguments "conditional_vars" {
   commands = [
     "plan",
     "apply",
     "destroy"
   ]

   # overrides for common values go in terraform.tfvars for the relative folder.
   optional_var_files = [
    "${get_terragrunt_dir()}/terraform.tfvars"
   ]
  }
}

# Inputs that need to be determined at the environment level.
# TODO: Once global variables are implemented by Terragrunt, move unique inputs to
# the resource level to provide better context.
inputs = {

  region = "${local.region}"
  users = "${local.users}"
  group-name = "${local.group-name}"
  role-name = "${local.role-name}"
  policy-name = "${local.policy-name}"
  allowed_roles = "${local.allowed_roles}"
  trusted_role_arn = "${local.trusted_role_arn}"
  }
