#!/usr/bin/env bash

source $KWD/bin/shell-logger

AWS_CMD=${AWS_CMD:-aws}

if ${AWS_CMD} s3api head-bucket --region $AWS_REGION --bucket "$AWS_TERRAFORM_STATE_BUCKET" 2>/dev/null; then

      info "$AWS_TERRAFORM_STATE_BUCKET s3 Bucket exists and region is $AWS_REGION" 

else 

      info "Creating  S3 Bucket with name $AWS_TERRAFORM_STATE_BUCKET in region $AWS_REGION"

      cd $KWD/terraform/s3

      terraform init -var name="$AWS_TERRAFORM_STATE_BUCKET"   1>std_out.log
      RESULT=$?
      if [ $RESULT -eq 0 ]; then
            info "Terraform State S3 bucket initialized "
      else
            exit 1
      fi


      terraform plan -out backend-s3.tfplan -var name="$AWS_TERRAFORM_STATE_BUCKET"  -var-file="$KWD/$ENVIRONMENT.tfvars" 1>std_out.log
      RESULT=$?
      if [ $RESULT -eq 0 ]; then
            info "Terraform State S3 bucket  plan created "
      else
            exit 1
      fi

      
      terraform apply -auto-approve backend-s3.tfplan   1>std_out.log
        RESULT=$?
      if [ $RESULT -eq 0 ]; then
            info "Terraform State S3 bucket successful "
      else
            exit 1
      fi

        notice "Wait for the S3 bucket is created"
        ${AWS_CMD} s3api wait bucket-exists --bucket="${AWS_TERRAFORM_STATE_BUCKET}"

      cd $KWD

fi 

TABLE_STATUS=$(${AWS_CMD} dynamodb describe-table --region $AWS_REGION --table-name "$AWS_TERRAFORM_DYNAMODB_TABLE" 2> /dev/null | jq -r .'Table.TableStatus')

if [ "$TABLE_STATUS" = "ACTIVE" ]
then

      info "$AWS_TERRAFORM_DYNAMODB_TABLE DynamoDB Table exists" 

else 

      info "Creating  DynamoDB Table with name $AWS_TERRAFORM_DYNAMODB_TABLE"

      cd $KWD/terraform/dynamodb

      terraform init -var name="$AWS_TERRAFORM_DYNAMODB_TABLE"    1>std_out.log

      RESULT=$?
      if [ $RESULT -eq 0 ]; then
            info "Terraform DynamoDB initialized "
      else
            exit 1
      fi


      terraform plan -out backend-db.tfplan -var name="$AWS_TERRAFORM_DYNAMODB_TABLE" -var-file="$KWD/$ENVIRONMENT.tfvars"  1>std_out.log

      RESULT=$?
      if [ $RESULT -eq 0 ]; then
            info "Terraform DynamoDB plan created "
      else
            exit 1
      fi


      terraform apply -auto-approve backend-db.tfplan    1>std_out.log

      RESULT=$?
      if [ $RESULT -eq 0 ]; then
        info "Terraform DynamoDB apply successful"
      else
            exit 1
      fi
        notice "Wait for the DynamoDB table is created"
        ${AWS_CMD} dynamodb wait table-exists --table-name="${AWS_TERRAFORM_DYNAMODB_TABLE}"
      cd $KWD
fi 

