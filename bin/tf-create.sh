#!/usr/bin/env bash
source $KWD/bin/shell-logger

cd $KWD/terraform/${TF_STACK}

   info  "Creating ${TF_STACK} terraform stack in region ${AWS_REGION}"
   notice "VPC creation takes approximately 5 minutes......."
 
   info "TERRAFORM_STATE_BUCKET" "${AWS_TERRAFORM_STATE_BUCKET}"
   info "TERRAFORM_KEY" "${AWS_REGION}/${ENVIRONMENT}/${TF_STACK}/terraform.tfstate"
 
   terraform init \
    -backend-config "bucket=$AWS_TERRAFORM_STATE_BUCKET" \
    -backend-config "key=$AWS_REGION/$ENVIRONMENT/$TF_STACK/terraform.tfstate" \
    -backend-config "dynamodb_table=$AWS_TERRAFORM_DYNAMODB_TABLE" \
    -backend-config "region=${AWS_REGION}"   1>std_out.log
   
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        info "Terraform initialized "
    else
        error "Terraform VPC initialize failed"
        exit 1
    fi

    terraform plan -out ${ENVIRONMENT}-${TF_STACK}.tfplan  -var-file="$KWD/$ENVIRONMENT.tfvars"  1>std_out.log

    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        info "Terraform created plan "
    else
        error "Terraform VPC plan failed"
        exit 1
    fi

    info "Terraform creating VPC"
    terraform apply -auto-approve ${ENVIRONMENT}-${TF_STACK}.tfplan  1>std_out.log
     
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        info "Terraform Created VPC Successfully"
   
    else
        error "Terraform VPC Create failed"
        exit 1
    fi

  
cd $KWD
 
