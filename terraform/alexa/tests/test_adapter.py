import io
import json
from pathlib import Path
import sys
import threading
import unittest
from unittest.mock import MagicMock
import urllib.error
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from adapter import Adapter, NoRedirect, SafeError, Upstream, serve


PATH = '/v1/skills/test/stages/development/manifest'
OLD = {'manifest': {'value': 'old'}}
NEW = {'manifest': {'value': 'new'}}


class AdapterTests(unittest.TestCase):
    def test_rejects_out_of_scope_and_invalid_payload(self):
        upstream = MagicMock()
        adapter = Adapter(upstream, [PATH])
        with self.assertRaises(SafeError):
            adapter.put('/other', NEW)
        with self.assertRaises(SafeError):
            adapter.put(PATH, {'unexpected': {}})
        upstream.request.assert_not_called()

    def test_metadata_updates_never_write(self):
        upstream = MagicMock()
        upstream.request.return_value = (200, OLD, 'fresh-version')
        Adapter(upstream, [PATH]).put(PATH, OLD)
        upstream.request.assert_called_once_with('GET', PATH)

    def test_missing_etag_refuses_write(self):
        upstream = MagicMock()
        upstream.request.return_value = (200, OLD, None)
        with self.assertRaisesRegex(SafeError, 'ETag'):
            Adapter(upstream, [PATH]).put(PATH, NEW)
        self.assertEqual(upstream.request.call_count, 1)

    def test_waits_for_build_and_configuration_with_fresh_etag(self):
        upstream = MagicMock()
        upstream.request.side_effect = [
            (200, OLD, 'fresh-version'),
            (202, None, None),
            (200, {'manifest': {'lastUpdateRequest': {'status': 'IN_PROGRESS'}}}, None),
            (200, {'manifest': {'eTag': 'new-version', 'lastUpdateRequest': {'status': 'SUCCEEDED'}}}, None),
            (200, OLD, 'old-version'),
            (200, {'manifest': {'eTag': 'new-version', 'lastUpdateRequest': {'status': 'SUCCEEDED'}}}, None),
            (200, NEW, 'new-version'),
        ]
        sleep = MagicMock()
        Adapter(upstream, [PATH], sleep=sleep).put(PATH, NEW)
        upstream.request.assert_any_call('PUT', PATH, json.dumps(NEW).encode(), 'fresh-version')
        self.assertEqual(sleep.call_count, 2)

    def test_previous_success_does_not_complete_new_build(self):
        upstream = MagicMock()
        upstream.request.side_effect = [
            (200, OLD, 'old-version'), (202, None, None),
            (200, {'manifest': {'eTag': 'old-version', 'lastUpdateRequest': {'status': 'SUCCEEDED'}}}, None),
            (200, {'manifest': {'eTag': 'new-version', 'lastUpdateRequest': {'status': 'SUCCEEDED'}}}, None),
            (200, NEW, 'new-version'),
        ]
        sleep = MagicMock()
        Adapter(upstream, [PATH], sleep=sleep).put(PATH, NEW)
        self.assertEqual(sleep.call_count, 1)

    def test_failed_build_does_not_report_success(self):
        upstream = MagicMock()
        upstream.request.side_effect = [
            (200, OLD, 'v'), (202, None, None),
            (200, {'manifest': {'lastUpdateRequest': {'status': 'FAILED'}}}, None),
        ]
        with self.assertRaisesRegex(SafeError, 'build failed'):
            Adapter(upstream, [PATH]).put(PATH, NEW)

    def test_build_timeout(self):
        upstream = MagicMock()
        upstream.request.side_effect = [(200, OLD, 'v'), (202, None, None)]
        with self.assertRaisesRegex(SafeError, 'timed out'):
            Adapter(upstream, [PATH], monotonic=MagicMock(side_effect=[0, 2]), timeout=1).put(PATH, NEW)

    def test_account_secret_is_not_expected_from_read_api(self):
        path = PATH.removesuffix('manifest') + 'accountLinkingClient'
        upstream = MagicMock()
        upstream.request.side_effect = [
            (200, {'accountLinkingResponse': {'clientId': 'old'}}, 'v'),
            (204, None, None),
            (200, {'accountLinkingResponse': {'clientId': 'new'}}, 'v2'),
        ]
        Adapter(upstream, [path]).put(path, {'accountLinkingRequest': {'clientId': 'new', 'clientSecret': 'test-only'}})

    def test_mismatch_is_an_error(self):
        path = PATH.removesuffix('manifest') + 'accountLinkingClient'
        upstream = MagicMock()
        upstream.request.side_effect = [(200, {}, 'v'), (204, None, None), (200, {}, 'v2')]
        with self.assertRaisesRegex(SafeError, 'does not match'):
            Adapter(upstream, [path]).put(path, {'accountLinkingRequest': {'clientId': 'new'}})


class TransportTests(unittest.TestCase):
    def test_local_adapter_requires_session_and_restricts_methods_and_paths(self):
        upstream = MagicMock()
        server = serve(Adapter(upstream, [PATH]), 'test-session')
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = 'http://localhost:' + str(server.server_port)
            cases = [('GET', PATH, '', 403), ('POST', PATH, 'Bearer test-session', 405), ('GET', '/outside', 'Bearer test-session', 502)]
            for method, path, authorization, status in cases:
                request = urllib.request.Request(base + path, method=method, headers={'Authorization': authorization})
                with self.assertRaises(urllib.error.HTTPError) as error:
                    urllib.request.urlopen(request, timeout=2)
                self.assertEqual(error.exception.code, status)
                error.exception.close()
            upstream.request.assert_not_called()
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)

    def test_redirect_is_rejected(self):
        request = urllib.request.Request('https://example.invalid', headers={'Authorization': 'Bearer test-only'})
        self.assertIsNone(NoRedirect().redirect_request(request, None, 307, '', {}, 'https://other.invalid'))

    def test_absolute_or_encoded_path_rejected_before_authentication(self):
        token = MagicMock()
        upstream = Upstream(token)
        for path in ['https://other.invalid', '/v1/skills/../x', '/v1/skills/%2f', '/v1/skills/x?query']:
            with self.assertRaises(SafeError):
                upstream.request('GET', path)
        token.assert_not_called()

    def test_upstream_error_body_is_not_exposed(self):
        upstream = Upstream(lambda: 'test-only')
        upstream.opener = MagicMock()
        upstream.opener.open.side_effect = urllib.error.HTTPError('https://example.invalid', 403, 'secret detail', {}, io.BytesIO(b'secret detail'))
        with self.assertRaises(SafeError) as error:
            upstream.request('GET', PATH)
        self.assertNotIn('secret', str(error.exception))

    def test_writes_are_never_retried(self):
        upstream = Upstream(lambda: 'test-only', sleep=MagicMock())
        upstream.opener = MagicMock()
        upstream.opener.open.side_effect = urllib.error.HTTPError('https://example.invalid', 503, '', {}, io.BytesIO())
        with self.assertRaises(SafeError):
            upstream.request('PUT', PATH, b'{}', 'v')
        self.assertEqual(upstream.opener.open.call_count, 1)


if __name__ == '__main__':
    unittest.main()
