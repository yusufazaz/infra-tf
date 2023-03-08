#!/usr/bin/env bash
source $KWD/bin/shell-logger

cd $KWD/terraform/${EKS_STACK}

info "Creating ${EKS_STACK} terraform stack"
notice "EKS creation takes approximately 12 minutes......."

info "TERRAFORM_STATE_BUCKET" "${AWS_TERRAFORM_STATE_BUCKET}"
info "TERRAFORM_KEY" "${AWS_REGION}/${ENVIRONMENT}/${EKS_STACK}/terraform.tfstate"

EKS_CREATED=false

terraform init -upgrade \
    -backend-config "bucket=$AWS_TERRAFORM_STATE_BUCKET" \
    -backend-config "key=$AWS_REGION/$ENVIRONMENT/$EKS_STACK/terraform.tfstate" \
    -backend-config "dynamodb_table=$AWS_TERRAFORM_DYNAMODB_TABLE" \
    -backend-config "region=${AWS_REGION}" 1>std_out.log

RESULT=$?
if [ $RESULT -eq 0 ]; then
    info "Terraform initialized for EKS"
else
    error "Terraform EKS initialize failed"

    exit 1
fi

terraform plan -out ${ENVIRONMENT}-${EKS_STACK}.tfplan -var-file="$KWD/$ENVIRONMENT.tfvars"  -var "tf_bucket=$AWS_TERRAFORM_STATE_BUCKET" 1>std_out.log

RESULT=$?
if [ $RESULT -eq 0 ]; then
    info "Terraform created plan for EKS "
else
    error "Terraform EKS plan failed"
    exit 1
fi

info "Terraform creating EKS"
terraform apply -auto-approve ${ENVIRONMENT}-${EKS_STACK}.tfplan 1>std_out.log

RESULT=$?
if [ $RESULT -eq 0 ]; then
    info "Terraform  EKS Stack Created Successfully"
    EKS_CREATED=true
fi


if [ "$EKS_CREATED" = true ]; then
    # terraform output -no-color -json config_map_aws_auth > $KWD/$ENVIRONMENT-config-map-aws-auth.json
    #terraform output -no-color kubeconfig >$KWD/$ENVIRONMENT-KubeConfig.yml

    eks_cluster_name=$(terraform output eks_cluster_name)
    eks_cluster_endpoint=$(terraform output eks_cluster_endpoint)

    echo "export ${ENVIRONMENT_NAME}_CLUSTER_NAME=$eks_cluster_name" >>$KWD/$ENVIRONMENT-cluster-env-values.sh
    echo "export ${ENVIRONMENT_NAME}_CLUSTER_ENDPOINT=$eks_cluster_endpoint" >>$KWD/$ENVIRONMENT-cluster-env-values.sh

fi

cd $KWD
