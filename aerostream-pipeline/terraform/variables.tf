variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for project resources"
  type        = string
  default     = "zeroscale"
}
