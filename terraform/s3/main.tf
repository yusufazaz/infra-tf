provider "aws" {
  region = "${var.aws_region}"
}


locals {
  name   = "${var.name}"
}

resource "aws_s3_bucket" "default" {
  bucket = local.name
  force_destroy = var.force_destroy
  tags = var.tags
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = "Disabled"
  }
}