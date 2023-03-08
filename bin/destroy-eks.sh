#!/usr/bin/env bash
source $KWD/bin/shell-logger

cd $KWD/terraform/${EKS_STACK}

   info  "Destroy ${EKS_STACK} terraform stack"
   notice "EKS Destroy takes approximately 10 minutes......."
  
   terraform init \
    -backend-config "bucket=$AWS_TERRAFORM_STATE_BUCKET" \
    -backend-config "key=$AWS_REGION/$ENVIRONMENT/$EKS_STACK/terraform.tfstate" \
    -backend-config "dynamodb_table=$AWS_TERRAFORM_DYNAMODB_TABLE" \
    -backend-config "region=${AWS_REGION}"   1>std_out.log
   
    
   terraform plan  -destroy -out ${ENVIRONMENT}-${EKS_STACK}.tfplan  -var-file="$KWD/$ENVIRONMENT.tfvars"   -var "tf_bucket=$AWS_TERRAFORM_STATE_BUCKET"   1>std_out.log
   terraform apply -auto-approve ${ENVIRONMENT}-${EKS_STACK}.tfplan  1>std_out.log
     
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        info "EKS Stack destroyed Successfully"
        EKS_CREATED=true
    else
        notice "EKS Destroy failed ....."
        exit 1
         
    fi

cd $KWD
 
