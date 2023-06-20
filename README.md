# Assume AWS Role with GCP Service Account OIDC Token

This acction assumes a specific AWS role using an instance service account.

Inputs are inspired by https://github.com/aws-actions/configure-aws-credentials

This action is only useful if GitHub Runner is running on GCP - which means self hosted runner.  
If you are not hosting your own runners, you probably do not need this.

## Inputs

## `role_to_assume`

**Required** Use the provided credentials to assume an IAM role and configure the Actions
environment with the assumed role credentials rather than with the provided
credentials

## `role_session_name`

**Required** Role session name (default: GitHubActions)

## `role_duration_seconds`

Role duration in seconds (default: 6 hours, 1 hour for OIDC/specified aws-session-token)

## Outputs

## `aws-account-id`

The AWS account ID for the provided credentials
