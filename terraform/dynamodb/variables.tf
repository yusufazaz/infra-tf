variable "aws_region" {
  description = "AWS region to create VPC"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  default     = "terraform"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "read_capacity" {
  default     = 5
  description = "DynamoDB read capacity units"
}

variable "write_capacity" {
  default     = 5
  description = "DynamoDB write capacity units"
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates the S3 bucket can be destroyed even if it contains objects. These objects are not recoverable"
  default     = false
}

variable "enable_server_side_encryption" {
  type        = bool
  description = "Enable DynamoDB server-side encryption"
  default     = true
}