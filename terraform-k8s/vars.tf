variable "namespace" {
  default = "test"
  type = string
}

variable "IAM_ROLE_ARN" {
 type = string
 default = "roles/iam.workloadIdentityUser"
}
