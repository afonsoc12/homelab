// Run the official CLI with its environment profile. Capture refreshed tokens
// through a pipe; prohibit profile writes, telemetry, redirects and CLI logging.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
let refreshed;
process.on('exit', (code) => {
  if (code === 0 && refreshed?.access_token) {
    fs.writeSync(1, JSON.stringify(refreshed));
  } else {
    process.exitCode = 1;
    fs.writeSync(2, 'ASK CLI token refresh failed\n');
  }
});
process.stdout.write = () => true;
process.stderr.write = () => true;

try {
  const root = process.env.ASK_CLI_ROOT;
  const load = createRequire(path.join(root, 'package.json'));
  if (load('./package.json').version !== '2.30.7') throw new Error('CLI version');
  const input = JSON.parse(fs.readFileSync(0, 'utf8'));
  process.env.ASK_REFRESH_TOKEN = input.token.refresh_token;
  process.env.ASK_VENDOR_ID = input.vendor_id;
  delete process.env.ASK_ACCESS_TOKEN;
  const axios = load('axios').default;
  axios.defaults.maxRedirects = 0;
  axios.defaults.timeout = 20000;
  const AppConfig = load('./dist/lib/model/app-config');
  AppConfig.prototype.write = () => { throw new Error('Profile writes prohibited'); };
  const { MetricClient } = load('./dist/lib/clients/metric-client');
  MetricClient.prototype._isEnabled = () => false;
  const Client = load('./dist/lib/clients/lwa-auth-code-client');
  const originalRefresh = Client.prototype.refreshToken;
  Client.prototype.refreshToken = function (token, callback) {
    return originalRefresh.call(this, token, (error, result) => {
      if (!error) refreshed = result;
      callback(error, result);
    });
  };
  process.argv = [process.execPath, path.join(root, 'dist/bin/ask-smapi.js'),
    'list-skills-for-vendor', '--max-results', '1', '--profile', '__ENVIRONMENT_ASK_PROFILE__'];
  load('./dist/bin/ask-smapi');
} catch {
  process.exitCode = 1;
}
