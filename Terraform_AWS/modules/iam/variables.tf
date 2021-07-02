variable "region" {
}

variable "users" {
  type = list(string)
}

variable "role-name" {
}

variable "group-name" {
}
variable "policy-name" {
}
variable "allowed_roles" {
  description = "The roles that this group is allowed to assume."
  type        = list(string)
}
variable "trusted_role_arn" {
  type = list(string)
}
