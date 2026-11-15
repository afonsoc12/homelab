import json
from pathlib import Path
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import run


class RunnerTests(unittest.TestCase):
    def test_ephemeral_connection_is_removed_even_on_failure(self):
        settings = {'api_uri': run.ORIGIN, 'skills': {'sample': {'id': 'amzn1.ask.skill.test'}}}
        env = {}
        with patch.object(run, 'decrypt', return_value={'settings': json.dumps(settings)}), patch.object(run, 'Tokens', return_value=lambda: 'test-only'):
            with self.assertRaisesRegex(ValueError, 'intentional'):
                with run.connection(env):
                    self.assertTrue(env.get('TF_VAR_smapi_endpoint'))
                    self.assertTrue(env.get('TF_VAR_smapi_session_token'))
                    raise ValueError('intentional')
        self.assertNotIn('TF_VAR_smapi_endpoint', env)
        self.assertNotIn('TF_VAR_smapi_session_token', env)

    def test_backend_credentials_go_only_into_environment(self):
        source = b'access_key = "test-key"\nsecret_key = "test-secret"\nregion = "test-region"\n'
        env = {'AWS_SESSION_TOKEN': 'stale'}
        with patch.object(run, 'capture', return_value=source):
            cleaned = run.backend(env)
        self.assertNotIn(b'test-key', cleaned)
        self.assertNotIn(b'test-secret', cleaned)
        self.assertIn(b'test-region', cleaned)
        self.assertEqual(env['AWS_ACCESS_KEY_ID'], 'test-key')
        self.assertEqual(env['AWS_SECRET_ACCESS_KEY'], 'test-secret')
        self.assertNotIn('AWS_SESSION_TOKEN', env)

    def test_unrecognized_backend_credentials_fail_closed(self):
        with patch.object(run, 'capture', return_value=b'access_key = unsupported_format\n'):
            with self.assertRaisesRegex(run.SafeError, 'Unsupported'):
                run.backend({})

    def test_debug_and_endpoint_overrides_removed_and_sensitive_schema_forced(self):
        with patch.dict(run.os.environ, {'TF_LOG': 'TRACE', 'TF_LOG_PATH': 'unsafe', 'NODE_OPTIONS': '--trace', 'ASK_LWA_TOKEN_HOST': 'unsafe', 'ASK_SMAPI_SERVER_BASE_URL': 'unsafe', 'API_DATA_IS_SENSITIVE': 'false'}, clear=True):
            env = run.environment()
        self.assertEqual(env, {'API_DATA_IS_SENSITIVE': 'true'})

    def test_subprocess_errors_do_not_expose_output(self):
        with patch.object(run.subprocess, 'run', return_value=MagicMock(returncode=1, stderr=b'private credential', stdout=b'private endpoint')):
            with self.assertRaises(run.SafeError) as error:
                run.capture(['terraform'])
        self.assertNotIn('private', str(error.exception))

    def test_expired_tokens_refresh_in_memory_without_cli_profile(self):
        tokens = object.__new__(run.Tokens)
        tokens.lock = run.threading.Lock()
        tokens.env = {}
        tokens.profile = {'vendor_id': 'test-vendor', 'token': {'access_token': 'expired-test', 'refresh_token': 'refresh-test', 'expires_at': '1970-01-01T00:00:00Z'}}
        refreshed = {'access_token': 'new-test', 'refresh_token': 'refresh-test', 'expires_at': '2999-01-01T00:00:00Z'}
        with patch.object(run, 'capture', return_value=json.dumps(refreshed).encode()) as command:
            self.assertEqual(tokens(), 'new-test')
            self.assertEqual(tokens(), 'new-test')
        self.assertEqual(command.call_count, 1)
        self.assertNotIn('refresh-test', repr(command.call_args.args))

    def test_rotated_refresh_token_is_persisted_only_through_sops(self):
        tokens = object.__new__(run.Tokens)
        tokens.lock = run.threading.Lock()
        tokens.env = {}
        tokens.profile = {'vendor_id': 'test-vendor', 'token': {'refresh_token': 'old-test', 'expires_at': '1970-01-01T00:00:00Z'}}
        refreshed = {'access_token': 'access-test', 'refresh_token': 'rotated-test', 'expires_at': '2999-01-01T00:00:00Z'}
        with patch.object(run, 'capture', side_effect=[json.dumps(refreshed).encode(), b'']) as command:
            self.assertEqual(tokens(), 'access-test')
        self.assertEqual(command.call_args_list[1].args[0][:3], ['sops', 'set', '--value-stdin'])
        self.assertNotIn('rotated-test', repr(command.call_args_list[1].args))


if __name__ == '__main__':
    unittest.main()
