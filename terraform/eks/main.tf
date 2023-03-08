provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Retrieve VPC data
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${var.tf_bucket}"
    key    = "${var.aws_region}/${var.environment}/vpc/terraform.tfstate"
    region = "${var.aws_region}"
  }
}


locals {
  name   = "k8-${data.terraform_remote_state.vpc.outputs.vpc_name}"
  region = var.aws_region

  cluster_version = var.cluster_version

  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  tags = merge(var.tags,{
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
    "kubernetes.io/cluster/${local.name}" = "shared"
    "env"      =  var.environment
  })
}

provider "bcrypt" {}


################################################################################
# Cluster
################################################################################

#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.9"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {
      configuration_values = jsonencode({
        env = {
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    
  }

  subnet_ids      = "${data.terraform_remote_state.vpc.outputs.private_subnets}"
  vpc_id          = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  eks_managed_node_groups = {
    initial = {
      instance_types = ["m5.large"]

      min_size     = 2
      max_size     = 10
      desired_size = 5
    }
  }

  
}

#  eks_managed_node_groups = {
#      mg_m5 = {
#        # 1> Node Group configuration
#        node_group_name        = "managed-ondemand"
#        create_launch_template = true              # false will use the default launch template
#        launch_template_os     = "amazonlinux2eks" # amazonlinux2eks or windows or bottlerocket
#        public_ip              = false             # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
#        pre_userdata           = <<-EOT
#                    yum install -y amazon-ssm-agent
#                    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
#                EOT
#        # 2> Node Group scaling configuration
#        desired_size    = 2
#        max_size        = 3
#        min_size        = 2
#        max_unavailable = 1 # or percentage = 20
#
#        # 3> Node Group compute configuration
#        ami_type       = "AL2_x86_64" # Amazon Linux 2(AL2_x86_64), AL2_x86_64_GPU, AL2_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64
#        capacity_type  = "ON_DEMAND"  # ON_DEMAND or SPOT
#        instance_types = ["m5.xlarge"] # List of instances used only for SPOT type
#        disk_size      = 100
#
#        # 4> Node Group network configuration
#        subnet_ids = "${data.terraform_remote_state.vpc.outputs.private_subnets}" # Mandatory - # Define private/public subnets list with comma separated ["subnet1","subnet2","subnet3"]
#
#        # optionally, configure a taint on the node group:
#        # k8s_taints = [{key= "purpose", value="execution", "effect"="NO_SCHEDULE"}]
#
#        k8s_labels = {
#          Environment = var.environment
#          Zone        = "dev"
#          WorkerType  = "ON_DEMAND"
#        }
#        additional_tags = merge({
#          ExtraTag    = "m5-on-demand"
#          Name        = "m5-on-demand"
#          subnet_type = "private"
#        }, local.tags)
#      }
#    }
#
#  tags = local.tags
#}

################################################################################
# Kubernetes Addons
################################################################################

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons"

  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  enable_argocd = true
  # This example shows how to set default ArgoCD Admin Password using SecretsManager with Helm Chart set_sensitive values.
  argocd_helm_config = {
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt_hash.argo.id
      }
    ]
  }

  keda_helm_config = {
    values = [
      {
        name  = "serviceAccount.create"
        value = "false"
      }
    ]
  }

  argocd_manage_add_ons = true # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_applications = {
    addons = {
      path               = "chart"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      add_on_application = true
    }
    workloads = {
      path               = "envs/dev"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-workloads.git"
      add_on_application = false
    }
  }

  # Add-ons
  enable_gatekeeper                     = false
  enable_aws_efs_csi_driver             = true
  enable_amazon_eks_aws_ebs_csi_driver  = true
  enable_aws_for_fluentbit              = true
  # Let fluentbit create the cw log group
  aws_for_fluentbit_create_cw_log_group = true
  enable_cert_manager                   = true
  enable_cluster_autoscaler             = false
  enable_karpenter                      = true
  enable_keda                           = true
  enable_metrics_server                 = true
  enable_prometheus                     = false
  enable_traefik                        = false
  enable_vpa                            = false
  enable_yunikorn                       = false
  enable_argo_rollouts                  = true

  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name
  karpenter_enable_spot_termination_handling = true


  tags = local.tags
}

#---------------------------------------------------------------
# ArgoCD Admin Password credentials with Secrets Manager
# Login to AWS Secrets manager with the same role as Terraform to extract the ArgoCD admin password with the secret name as "argocd"
#---------------------------------------------------------------
resource "random_password" "argocd" {
  length           = 8
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Argo requires the password to be bcrypt, we use custom provider of bcrypt,
# as the default bcrypt function generates diff for each terraform plan
resource "bcrypt_hash" "argo" {
  cleartext = random_password.argocd.result
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "argocd" {
  name                    = "${local.name}-secrets"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}


module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.9"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  create_irsa            = false # IRSA will be created by the kubernetes-addons module

  tags = local.tags
}


resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["r","c"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["8", "16", "32"]
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand
          operator: In
          values: ["spot"]
      kubeletConfiguration:
        containerRuntime: containerd
      limits:
        resources:
          cpu: 1000
      consolidation:
        enabled: true
      providerRef:
        name: default
      #ttlSecondsUntilExpired: 604800 # 7 Days = 7 * 24 * 60 * 60 Seconds
      #ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      instanceProfile: ${module.karpenter.instance_profile_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]
}

#resource "aws_eks_addon" "core_dns" {
#
#  cluster_name      = module.eks.cluster_name
#  addon_name        = "coredns"
#  resolve_conflicts = "OVERWRITE"
#  preserve = true
#  tags = merge(
#    local.tags,
#    {
#      "eks_addon" = "coredns"
#    }
#  )
#}
#
#resource "aws_eks_addon" "aws_ebs_csi_driver" {
#
#  cluster_name      = module.eks.cluster_name
#  addon_name        = "aws-ebs-csi-driver"
# #addon_version     = var.eks_addon_version_ebs_csi_driver
#  resolve_conflicts = "OVERWRITE"
#
#  preserve = true
#
#  tags = merge(
#    local.tags,
#    {
#      "eks_addon" = "ebs-csi-driver"
#    }
#  )
#}