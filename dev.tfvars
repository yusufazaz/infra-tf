vpc_cidr           = "10.163.24.0/22"
azs                = ["us-west-2a",  "us-west-2c"]
private_subnets    = ["10.163.24.0/24", "10.163.25.0/24"]
public_subnets     = ["10.163.26.0/24", "10.163.27.0/24"]
aws_region         = "us-west-2"
environment        = "dev"
create_bastion     = "1"
cluster_version    = "1.25"
ec2_user_key       = "gtl-dev-rsa-gitlab"
account_hostedzone = "gtldev.net."
app_name           = "eks-bp"
map_roles = [
    {
      rolearn  = "arn:aws:iam::516176675572:role/dev-eks-admin"
      username = "admin:{{SessionName}}" # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"] # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    } 
  ]
