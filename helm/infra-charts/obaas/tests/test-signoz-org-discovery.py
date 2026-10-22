#!/usr/bin/env python3
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.
"""Exercise setup API calls and reconciliation without a live SigNoz instance."""

import importlib.util
import io
import json
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


CHART = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("setup", CHART / "files/signoz/setup.py")
setup = importlib.util.module_from_spec(SPEC)
sys.dont_write_bytecode = True
SPEC.loader.exec_module(setup)
ORG_ID = "01a16416-98e2-7709-b4a8-584fddf3a379"


def dashboard(title):
    return {"schemaVersion": "v6", "spec": {"display": {"name": title}}}


class SetupTest(unittest.TestCase):
    def login(self, orgs, explicit=None):
        with tempfile.TemporaryDirectory() as directory:
            auth = Path(directory)
            (auth / "email").write_text("admin+setup@example.com")
            (auth / "password").write_text('secret"\\password')
            if explicit is not None:
                (auth / "orgID").write_text(explicit)
            client = setup.SigNoz("http://signoz:8080")
            responses = [{"data": {"orgs": orgs}}, {"data": {"accessToken": "jwt"}}]
            if explicit:
                responses.pop(0)
            with patch.object(client, "request", side_effect=responses) as request:
                client.login(auth)
            return client, request.call_args_list

    def test_single_org_and_encoded_email(self):
        client, calls = self.login([{"id": ORG_ID}], explicit="")
        self.assertEqual(client.token, "jwt")
        self.assertIn("email=admin%2Bsetup%40example.com", calls[0].args[1])
        self.assertEqual(calls[1].args[2], {
            "email": "admin+setup@example.com", "password": 'secret"\\password', "orgID": ORG_ID,
        })

    def test_missing_ambiguous_or_invalid_org_fails(self):
        for orgs in [[], [{"id": ORG_ID}] * 2, [{"id": "invalid"}]]:
            with self.subTest(orgs=orgs), self.assertRaises(ValueError):
                self.login(orgs)

    def test_explicit_org_skips_discovery(self):
        _, calls = self.login([], explicit=ORG_ID)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0].args[1], "/api/v2/sessions/email_password")

    def test_readiness_retries(self):
        client = setup.SigNoz("http://signoz:8080")
        with patch.object(client, "request", side_effect=[RuntimeError("not ready"), {}]) as request:
            with patch.object(setup.time, "sleep") as sleep:
                client.wait_until_ready()
        self.assertEqual(request.call_count, 2)
        sleep.assert_called_once_with(5)

    def test_pagination_and_exact_title_reconciliation(self):
        title = 'OBaaS "System" \\ metrics'
        bundled = dashboard(title)
        legacy = dict(dashboard(title), id="legacy", legacy=True)
        user = dict(dashboard("My own dashboard"), id="user")
        duplicate = dict(dashboard(title), id="duplicate")
        client = setup.SigNoz("http://signoz:8080")
        responses = [
            {"data": {"dashboards": [legacy, user], "total": 3}},
            {"data": {"dashboards": [duplicate], "total": 3}},
            None, None, {},
        ]
        with patch.object(client, "request", side_effect=responses) as request:
            setup.reconcile(client, [bundled])
        self.assertEqual([call.args[:2] for call in request.call_args_list], [
            ("GET", "/api/v2/dashboards?limit=200&offset=0"),
            ("GET", "/api/v2/dashboards?limit=200&offset=2"),
            ("DELETE", "/api/v2/dashboards/legacy"),
            ("DELETE", "/api/v2/dashboards/duplicate"),
            ("POST", "/api/v2/dashboards"),
        ])

    def test_incomplete_pagination_stops_before_deleting(self):
        client = setup.SigNoz("http://signoz:8080")
        with patch.object(client, "request", return_value={"data": {"dashboards": [], "total": 1}}) as request:
            with self.assertRaises(ValueError):
                setup.reconcile(client, [dashboard("System")])
        self.assertEqual(request.call_count, 1)

    def test_load_bundled_dashboards_and_symlinked_configmap(self):
        bundled = setup.load_dashboards([CHART / "dashboards/1", CHART / "dashboards/2"])
        self.assertGreater(len(bundled), 10)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "..data").mkdir()
            (path / "..data/test.json").write_text(json.dumps(dashboard("System")))
            (path / "test.json").symlink_to("..data/test.json")
            self.assertEqual(setup.load_dashboards([path]), [dashboard("System")])

    def test_request_json_and_authorization(self):
        client = setup.SigNoz("http://signoz:8080")
        client.token = "jwt"
        payload = {"password": 'special"\\\ncharacters'}
        with patch.object(setup, "urlopen") as urlopen:
            urlopen.return_value.__enter__.return_value.read.return_value = b'{"data": {}}'
            self.assertEqual(client.request("POST", "/test", payload), {"data": {}})
        request = urlopen.call_args.args[0]
        self.assertEqual(json.loads(request.data), payload)
        self.assertEqual(request.get_header("Authorization"), "Bearer jwt")

    def test_http_failure_does_not_expose_response_body(self):
        client = setup.SigNoz("http://signoz:8080")
        error = setup.HTTPError("http://signoz", 401, "secret body", {}, io.BytesIO(b"secret"))
        with patch.object(setup, "urlopen", side_effect=error):
            with self.assertRaisesRegex(RuntimeError, "HTTP 401") as raised:
                client.request("POST", "/login")
        self.assertNotIn("secret", str(raised.exception))
        error.close()

    @unittest.skipUnless(shutil.which("helm"), "Helm is unavailable")
    def test_render_is_database_independent(self):
        for postgres in ["false", "true"]:
            result = subprocess.run(
                ["helm", "template", "setup-test", str(CHART), "--is-upgrade",
                 "--set", f"signoz.postgresql.enabled={postgres}"],
                capture_output=True, text=True, check=True,
            )
            job = next(doc for doc in result.stdout.split("\n---")
                       if "kind: Job" in doc and "name: setup-test-signoz-setup\n" in doc)
            self.assertIn('command: ["python3", "-u", "/signoz-setup/setup.py"]', job)
            self.assertIn("container-registry.oracle.com/os/oraclelinux:9", job)
            for removed in ["sqlite(", "clickhouse-local", "signoz-db", "shared-data", "podAffinity:"]:
                self.assertNotIn(removed, job)
            self.assertIn("name: signoz-authn", job)
            self.assertIn("/api/v2/sessions/context", result.stdout)


if __name__ == "__main__":
    unittest.main()
