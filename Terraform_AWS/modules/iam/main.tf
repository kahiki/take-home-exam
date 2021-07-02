provider "aws" {
  region = var.region
}

########
#This was referenced from here https://github.com/trussworks/terraform-aws-iam-user-group/blob/main/examples/simple/main.tf
########
locals {
  users = toset(var.users)1
}
resource "aws_iam_user" "users" {
  for_each      = local.users
  name          = each.value
  force_destroy = true
}
#########
#This was referenced from https://github.com/trussworks/terraform-aws-iam-user-group/blob/main/main.tf
#########
resource "aws_iam_group" "deny" {
  name = var.group-name
}
resource "aws_iam_group_membership" "deny" {
  group = aws_iam_group.deny.id
  name  = var.group-name
  users = var.users
}
########
#This was referenced from here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
########
resource "aws_iam_role" "role" {
  name = var.role-name
  assume_role_policy = "${file("assumerolepolicy.json")}"
}

resource "aws_iam_policy" "policy" {
  name        = var.policy-name
  description = "A test policy"
  policy      = "${file("policys.json")}"
}
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  groups     = ["${aws_iam_group.deny.name}]"]
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

