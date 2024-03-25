import * as core from '@actions/core'
import {STS} from '@aws-sdk/client-sts'
import fs from 'fs'
import * as google from 'googleapis'
import path from 'path'

async function run(): Promise<void> {
  try {
    if (process.env.GOOGLE_CREDENTIALS) {
      core.debug('Writing Google credentials from env to file')
      const GOOGLE_APPLICATION_CREDENTIALS = path.join(__dirname, 'gcp-credentials.json')
      fs.writeFileSync(GOOGLE_APPLICATION_CREDENTIALS, process.env.GOOGLE_CREDENTIALS)
      process.env.GOOGLE_APPLICATION_CREDENTIALS = GOOGLE_APPLICATION_CREDENTIALS
    }

    core.debug('Getting inputs')
    const roleToAssume = core.getInput('role_to_assume', {required: true})
    const roleSessionName = core.getInput('role_session_name') ?? 'GithubActions'
    const roleDurationSeconds = core.getInput('role_duration_seconds') ?? '900'
    const audience = 'actions.github.com'
    const region = core.getInput('aws_region') ?? 'us-east-1'

    core.debug(
      `Inputs: ${JSON.stringify({
        roleToAssume,
        roleSessionName,
        roleDurationSeconds,
        audience,
        region
      })}`
    )

    core.debug('Getting access token from Google')
    const gauth = await new google.Auth.GoogleAuth().getIdTokenClient(audience)
    const gtoken = await gauth.idTokenProvider.fetchIdToken(audience)

    if (!gtoken) throw new Error('Could not get access token from Google')
    core.setSecret(gtoken)

    core.debug('Assuming role with AWS')
    const sts = new STS({region})
    const {Credentials} = await sts.assumeRoleWithWebIdentity({
      RoleArn: roleToAssume,
      RoleSessionName: roleSessionName,
      DurationSeconds: parseInt(roleDurationSeconds),
      WebIdentityToken: gtoken
    })
    if (!Credentials || !(Credentials.AccessKeyId && Credentials.SecretAccessKey && Credentials.SessionToken))
      throw new Error('Could not assume role with AWS')
    core.debug('Setting secrets')
    core.setSecret(Credentials.AccessKeyId)
    core.setSecret(Credentials.SecretAccessKey)
    core.setSecret(Credentials.SessionToken)

    core.debug('Testing AWS by getting caller identity')
    const {Account, Arn} = await new STS({
      region,
      credentials: {
        accessKeyId: Credentials.AccessKeyId,
        secretAccessKey: Credentials.SecretAccessKey,
        sessionToken: Credentials.SessionToken
      }
    }).getCallerIdentity({})

    core.info(`Assumed role: ${Arn}`)
    core.debug('Exporting variables')
    core.exportVariable('AWS_ACCESS_KEY_ID', Credentials.AccessKeyId)
    core.exportVariable('AWS_SECRET_ACCESS_KEY', Credentials.SecretAccessKey)
    core.exportVariable('AWS_SESSION_TOKEN', Credentials.SessionToken)
    core.exportVariable('AWS_DEFAULT_REGION', region)
    core.exportVariable('AWS_REGION', region)

    core.debug('Setting outputs')
    core.setOutput('aws-account-id', Account)
  } catch (error) {
    if (error instanceof Error) core.setFailed(error.message)
    throw error
  }
}

run()
