provider "aws" {
  region = var.aws_region
}

locals {
  name   = "${var.name}"
}


resource "aws_dynamodb_table" "tftable" {
  count          = var.enable_server_side_encryption ? 1 : 0
  name           = local.name
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  hash_key = "LockID"

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
