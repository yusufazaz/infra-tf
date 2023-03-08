variable "aws_region" {
  description = "AWS region to create VPC"
  default     = "us-east-2"
}

variable "environment" {
  type        = string
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "vpc_cidr" {}

variable "azs" {
  description = "Array AZs. Must match number of public and or private subnets"
  type        = list
}

variable "public_subnets" {
  description = "Array of public subnet CIDR. Must match number of AZs"
  type        = list
}

variable "private_subnets" {
  description = "Array of private subnet CIDR. Must match number of AZs"
  type        = list
}

variable "app_name" {
  type        = string
  default     = "vpc-pci"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}
