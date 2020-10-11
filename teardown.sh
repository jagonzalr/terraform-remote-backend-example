#!/bin/bash

echo -e "********** Starting teardown **********\n"

STATE_BUCKET_NAME='my-service-state-bucket'
LOCAL_STATE_DIRECTORY='infrastructure/global/state_local'
REMOTE_STATE_DIRECTORY='infrastructure/global/state_remote'
TMP_STATE_DIRECTORY='infrastructure/global/temp'

echo -e "Deleting local terraform state..."
find . -type d -name ".terraform" -prune -exec rm -rf {} \;
echo -e "Deleted local terraform state..."

aws ssm get-parameter --name "$STATE_BUCKET_NAME"

if [ $? == 0 ]; then

	STATE_BUCKET_VALUE=`aws ssm get-parameters --with-decryption --names "${STATE_BUCKET_NAME}"  --query 'Parameters[*].Value' --output text`
	echo -e $STATE_BUCKET_VALUE
	echo -e "Got State Bucket Name."
	mkdir $TMP_STATE_DIRECTORY

	echo -e "Copying files to init remote state..."
	cp -r "$REMOTE_STATE_DIRECTORY/" "$TMP_STATE_DIRECTORY"
	echo -e "Copied files to init remote state..."

	cd $TMP_STATE_DIRECTORY
	terraform init -backend-config="../../../backend.hcl" -backend-config="bucket=$STATE_BUCKET_VALUE" -input=false -force-copy
	cd ../../..

	echo -e "Copying files to init local state..."
	cp -r "$LOCAL_STATE_DIRECTORY/" "$TMP_STATE_DIRECTORY"
	echo -e "Copied files to init local state..."

	cd $TMP_STATE_DIRECTORY
	terraform init -input=false -force-copy
	terraform destroy -var-file="../../../global.tfvars" -input=false -auto-approve
	cd ../../..

	aws ssm delete-parameter --name "$STATE_BUCKET_NAME"
	rm -rf $TMP_STATE_DIRECTORY
fi

echo -e "********** Finished teardown **********\n"