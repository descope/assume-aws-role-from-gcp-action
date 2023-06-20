import * as process from 'process'
import * as cp from 'child_process'
import * as path from 'path'
import * as fs from 'fs'
import {test} from '@jest/globals'
require('dotenv').config()

// shows how the runner will run a javascript action with env / stdout protocol
test('test runs', () => {
  if (process.env.GOOGLE_CREDENTIALS) {
    const GOOGLE_APPLICATION_CREDENTIALS = path.join(__dirname, 'gcp-credentials.json')
    fs.writeFileSync(GOOGLE_APPLICATION_CREDENTIALS, process.env.GOOGLE_CREDENTIALS)
    process.env.GOOGLE_APPLICATION_CREDENTIALS = GOOGLE_APPLICATION_CREDENTIALS
  }
  const np = process.execPath
  const ip = path.join(__dirname, '..', 'lib', 'main.js')
  const options: cp.ExecFileSyncOptions = {
    env: process.env
  }
  cp.execFileSync(np, [ip], options)
})
