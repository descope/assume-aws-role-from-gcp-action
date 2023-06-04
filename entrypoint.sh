#!/bin/sh -l

aws --version
gcloud --version

echo "::debug::Get GCP Identity Token"
GOOGLE_CREDENTIAL=$(gcloud auth print-identity-token)

echo "::debug::Assume AWS Role $1 with session name $2 and duration $3"
CREDENTIALS=$(aws sts assume-role-with-web-identity --role-arn "$1" --role-session-name "$2" --duration-seconds "$3" --web-identity-token "$GOOGLE_CREDENTIAL")
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

AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .Credentials.AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .Credentials.SecretAccessKey)
AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r .Credentials.SessionToken)
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

