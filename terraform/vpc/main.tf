provider "aws" {
  region = var.aws_region
}

provider "random" {
  version = "~> 2.1"
}

terraform {
  required_version = ">= 1.0.0"
  backend "s3" {}
}



resource "random_string" "suffix" {
  length  = 4
  special = false
}


data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}



locals {
  name   = "${var.app_name}-${random_string.suffix.result}"
  region = var.aws_region

  cluster_version = "1.25"

  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  tags = merge(var.tags,{
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
    "kubernetes.io/cluster/${local.name}" = "shared"
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = merge({
    "kubernetes.io/role/elb" = 1
  },var.tags)

  private_subnet_tags = merge({
    "kubernetes.io/role/internal-elb" = 1
  },var.tags)

  tags = local.tags
}

#
#module "vpc_endpoints" {
#  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#
#  vpc_id             = module.vpc.vpc_id
#  security_group_ids = [data.aws_security_group.default.id]
#
#  endpoints = {
#    s3 = {
#      service = "s3"
#      tags    = merge(local.tags,{ Name = "s3-vpc-endpoint" })
#    },
#    dynamodb = {
#      service         = "dynamodb"
#      service_type    = "Gateway"
#      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
#      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
#      tags            = merge(local.tags,{ Name = "dynamodb-vpc-endpoint" })
#    },
#    ssm = {
#      service             = "ssm"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      security_group_ids  = [aws_security_group.vpc_tls.id]
#    },
#    ssmmessages = {
#      service             = "ssmmessages"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#    },
#    lambda = {
#      service             = "lambda"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#    },
#    ec2 = {
#      service             = "ec2"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      security_group_ids  = [aws_security_group.vpc_tls.id]
#    },
#    ec2messages = {
#      service             = "ec2messages"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#    },
#    ecr_api = {
#      service             = "ecr.api"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#    },
#    ecr_dkr = {
#      service             = "ecr.dkr"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#    },
#    kms = {
#      service             = "kms"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      security_group_ids  = [aws_security_group.vpc_tls.id]
#    }
#  }
#
#  tags = local.tags
#}
#
#
#data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
#  statement {
#    effect    = "Deny"
#    actions   = ["dynamodb:*"]
#    resources = ["*"]
#
#    principals {
#      type        = "*"
#      identifiers = ["*"]
#    }
#
#    condition {
#      test     = "StringNotEquals"
#      variable = "aws:sourceVpce"
#
#      values = [module.vpc.vpc_id]
#    }
#  }
#}
#
#data "aws_iam_policy_document" "generic_endpoint_policy" {
#  statement {
#    effect    = "Deny"
#    actions   = ["*"]
#    resources = ["*"]
#
#    principals {
#      type        = "*"
#      identifiers = ["*"]
#    }
#
#    condition {
#      test     = "StringNotEquals"
#      variable = "aws:SourceVpc"
#
#      values = [module.vpc.vpc_id]
#    }
#  }
#}
#
#
#resource "aws_security_group" "vpc_tls" {
#  name_prefix = "${local.name}-vpc_tls"
#  description = "Allow TLS inbound traffic"
#  vpc_id      = module.vpc.vpc_id
#
#  ingress {
#    description = "TLS from VPC"
#    from_port   = 443
#    to_port     = 443
#    protocol    = "tcp"
#    cidr_blocks = [module.vpc.vpc_cidr_block]
#  }
#
#  tags = var.tags
#}