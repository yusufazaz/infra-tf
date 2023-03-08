#!/usr/bin/env bash

source $KWD/bin/shell-logger
info "Deleting  S3 Bucket with name $AWS_TERRAFORM_STATE_BUCKET"

if aws s3api head-bucket --bucket "$AWS_TERRAFORM_STATE_BUCKET" 2>/dev/null; then

      info "Deleting  S3 Bucket with name $AWS_TERRAFORM_STATE_BUCKET"
      aws s3api delete-objects \
    --bucket $AWS_TERRAFORM_STATE_BUCKET \
    --delete "$(aws s3api list-object-versions \
    --bucket "${AWS_TERRAFORM_STATE_BUCKET}" \
    --output=json \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
     sleep 60
    
    aws s3 rb s3://$AWS_TERRAFORM_STATE_BUCKET --force --region $AWS_REGION

fi 

if aws dynamodb describe-table --table-name "$AWS_TERRAFORM_DYNAMODB_TABLE" 2>/dev/null; then

      info "Deleting  DynamoDB Table with name $AWS_TERRAFORM_DYNAMODB_TABLE"
      aws dynamodb  delete-table --table-name $AWS_TERRAFORM_DYNAMODB_TABLE

fi
 