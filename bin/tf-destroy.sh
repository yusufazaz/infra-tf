#!/usr/bin/env bash
source $KWD/bin/shell-logger

 cd $KWD/terraform/${TF_STACK}

   info "Destroy ${TF_STACK}"
  

   terraform init \
    -backend-config "bucket=$AWS_TERRAFORM_STATE_BUCKET" \
    -backend-config "key=$AWS_REGION/$ENVIRONMENT/$TF_STACK/terraform.tfstate" \
    -backend-config "dynamodb_table=$AWS_TERRAFORM_DYNAMODB_TABLE" \
    -backend-config "region=${AWS_REGION}"   1>std_out.log
   
    terraform plan  -destroy -out ${ENVIRONMENT}-${TF_STACK}.tfplan  -var-file="$KWD/$ENVIRONMENT.tfvars"  1>std_out.log
    notice "Destroy in Progress"
    terraform apply -auto-approve ${ENVIRONMENT}-${TF_STACK}.tfplan  1>std_out.log
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
      info "Destroy Completed"
    else
      notice "Destroy Failed with error code $RESULT"
      exit 1
    fi
sleep 60

cd $KWD

 