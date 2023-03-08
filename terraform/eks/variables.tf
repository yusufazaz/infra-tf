variable "aws_region" {
  description = "AWS region to create VPC"
  default     = "us-west-2"
}

variable "environment" {
  type        = string
  description = "Solution name, e.g. 'dev' or 'prod'"
}

variable "cluster_version" {
  type        = string
  description = "Solution name, e.g. 'dev' or 'prod'"
}

variable "vpc_cidr" {
    default = "10.163.0.0/19"
}

variable "azs" {
  description = "Array AZs. Must match number of public and or private subnets"
  type        = list
  default     = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

variable "public_subnets" {
  description = "Array of public subnet CIDR. Must match number of AZs"
  type        = list
  default     =  ["10.163.28.0/24", "10.163.29.0/24", "10.163.30.0/24","10.163.31.0/24"]
}

variable "private_subnets" {
  description = "Array of private subnet CIDR. Must match number of AZs"
  type        = list
  default =  ["10.163.0.0/21", "10.163.8.0/21", "10.163.16.0/21","10.163.24.0/22"]
}

variable "app_name" {
  type        = string
  default     = "stack-name"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "tf_bucket" {}


variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
