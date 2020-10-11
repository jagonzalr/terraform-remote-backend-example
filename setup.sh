#!/bin/bash

echo -e "********** Starting setup **********\n"

STATE_BUCKET_NAME='my-service-state-bucket'
LOCAL_STATE_DIRECTORY='infrastructure/global/state_local'
REMOTE_STATE_DIRECTORY='infrastructure/global/state_remote'
TMP_STATE_DIRECTORY='infrastructure/global/temp'

echo -e "Deleting local terraform state..."
find . -type d -name ".terraform" -prune -exec rm -rf {} \;
echo -e "Deleted local terraform state..."

aws ssm get-parameter --name "$STATE_BUCKET_NAME"

if [ $? != 0 ]; then
	echo -e "\nCreating terraform state S3 bucket for remote state...\n"

	mkdir $TMP_STATE_DIRECTORY
	echo -e "Copying files to create S3 bucket using local state..."
	cp -r "$LOCAL_STATE_DIRECTORY/" "$TMP_STATE_DIRECTORY"
	echo -e "Copied files to create S3 bucket using local state"

	cd $TMP_STATE_DIRECTORY
	terraform init -input=false
	terraform apply -var-file="../../../global.tfvars" -input=false -auto-approve
	STATE_BUCKET_VALUE=`terraform output s3_state_bucket`
	cd ../../..

	echo -e "Writing parameter for state bucket to parameter store..."
	aws ssm put-parameter --name "$STATE_BUCKET_NAME" --value "$STATE_BUCKET_VALUE" --type "SecureString"
	echo -e "Wrote parameter for state bucket to parameter store"

	echo -e "Copying files to enable remote state..."
	cp -r "$REMOTE_STATE_DIRECTORY/" "$TMP_STATE_DIRECTORY"
	echo -e "Copied files to enable remote state"

	cd $TMP_STATE_DIRECTORY
	terraform init -backend-config="../../../backend.hcl" -backend-config="bucket=$STATE_BUCKET_VALUE" -input=false -force-copy
	terraform apply -var-file="../../../global.tfvars" -input=false -auto-approve
	cd ../../..
	rm -rf $TMP_STATE_DIRECTORY

	echo -e "\nCreated terraform state S3 bucket for remote state\n"
else
	echo -e "Terraform state S3 bucket already exists."
	echo -e "Getting State Bucket Name."
	STATE_BUCKET_VALUE=`aws ssm get-parameters --with-decryption --names "${STATE_BUCKET_NAME}"  --query 'Parameters[*].Value' --output text`
	echo -e $STATE_BUCKET_VALUE
	echo -e "Got State Bucket Name."
	cd $REMOTE_STATE_DIRECTORY
	terraform init -backend-config="../../../backend.hcl" -backend-config="bucket=$STATE_BUCKET_VALUE" -input=false -force-copy
  	terraform apply -var-file="../../../global.tfvars" -input=false -auto-approve
  	cd ../../..
fi

echo -e "********** Finshed setup **********\n"