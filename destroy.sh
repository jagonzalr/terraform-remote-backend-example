#!/bin/bash

ENVIRONMENT="dev"
STATE_BUCKET_NAME='my-service-state-bucket'
STATE_BUCKET_VALUE=`aws ssm get-parameters --with-decryption --names "${STATE_BUCKET_NAME}"  --query 'Parameters[*].Value' --output text`

cd infrastructure/$ENVIRONMENT/storage
terraform init -backend-config="../../../backend.hcl" -backend-config="bucket=$STATE_BUCKET_VALUE" -input=false -no-color
terraform destroy -var-file="../../../global.tfvars" -var-file="../environment.tfvars" -input=false -auto-approve -no-color
cd ../../..