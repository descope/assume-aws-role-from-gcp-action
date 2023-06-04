#!/bin/sh -l

aws --version
gcloud --version

ROLE_TO_ASSUME=$1
ROLE_SESSION_NAME=$2
ROLE_DURATION_SECONDS=$3

echo "::debug::Get GCP Identity Token"
GOOGLE_CREDENTIAL=$(gcloud auth print-identity-token)
echo "::add-mask::$GOOGLE_CREDENTIAL"
echo "::debug::Assume AWS Role ${ROLE_TO_ASSUME} with session name ${ROLE_SESSION_NAME} and duration ${ROLE_DURATION_SECONDS}"
CREDENTIALS_CMD="aws sts assume-role-with-web-identity \
    --role-arn $ROLE_TO_ASSUME \
    --role-session-name $ROLE_SESSION_NAME \
    --duration-seconds $ROLE_DURATION_SECONDS \
    --web-identity-token $GOOGLE_CREDENTIAL"

echo "::debug::Run command: $CREDENTIALS_CMD"
CREDENTIALS=$($CREDENTIALS_CMD)
# {
#     "Credentials": {
#         "AccessKeyId": "ASIAN...KAGJO",
#         "SecretAccessKey": "uZNykS...f/XvTz",
#         "SessionToken": "FwoGZXI...QeetKruBtt",
#         "Expiration": "2023-06-01T12:05:35Z"
#     },
#     "SubjectFromWebIdentityToken": "XXXX",
#     "AssumedRoleUser": {
#         "AssumedRoleId": "AR...:SESSION",
#         "Arn": "arn:aws:sts::123456789:assumed-role/ROLE/SESSION"
#     },
#     "Provider": "accounts.google.com",
#     "Audience": "XXXX"
# }

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r .Credentials.SessionToken)
echo "::debug::Export AWS Credentials"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> "$GITHUB_ENV"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> "$GITHUB_ENV"
echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> "$GITHUB_ENV"

echo "::debug::Mask AWS Credentials"
echo "::add-mask::$AWS_ACCESS_KEY_ID"
echo "::add-mask::$AWS_SECRET_ACCESS_KEY"
echo "::add-mask::$AWS_SESSION_TOKEN"

AWS_IDENTITY=$(aws sts get-caller-identity)
# {
#     "UserId": "AR...:SESSION",
#     "Account": "XXXXXX",
#     "Arn": "arn:aws:sts::123456789:assumed-role/ROLE/SESSION"
# }

AWS_ACCOUNT_ID=$(echo $AWS_IDENTITY | jq -r .Account)
AWS_ROLE_ARN=$(echo $AWS_IDENTITY | jq -r .Arn)

echo "::debug::Setting output variables"
echo "aws-account-id=$AWS_ACCOUNT_ID" >> "$GITHUB_OUTPUT"

