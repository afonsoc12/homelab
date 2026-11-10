"""Regression checks for the native DockerMan recreation path."""

import importlib.util
from pathlib import Path
import shlex
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location("unraid", Path(__file__).parents[1] / "filter_plugins/unraid.py")
unraid = importlib.util.module_from_spec(spec)
spec.loader.exec_module(unraid)


class NativeTemplateTests(unittest.TestCase):
    def render(self, service, source=None, meta=None):
        service = {"container_name": "app", "image": "example/app:1", **service}
        return ET.fromstring(unraid.unraid_template(
            service, source or {}, {"vpn": {"container_name": "privoxyvpn"}},
            {"default": {"name": "media"}}, meta or {},
        ))

    def test_shared_namespace_has_one_native_network_and_no_extra_net_flag(self):
        root = self.render({"network_mode": "service:vpn"})
        self.assertEqual(root.findtext("Network"), "container:privoxyvpn")
        self.assertNotIn("--net", root.findtext("ExtraParams"))
        self.assertEqual(self.render({"network_mode": "container:privoxyvpn"}).findtext("Network"),
                         "container:privoxyvpn")

    def test_host_and_custom_networks_survive_gui_recreation(self):
        self.assertEqual(self.render({"network_mode": "host"}).findtext("Network"), "host")
        self.assertEqual(self.render({"networks": {"default": None}}).findtext("Network"), "media")

    def test_vpn_privilege_healthcheck_and_sysctl_survive(self):
        root = self.render({
            "privileged": True, "restart": "unless-stopped",
            "sysctls": {"net.ipv4.conf.all.src_valid_mark": "1"},
            "healthcheck": {"test": ["CMD-SHELL", "ip addr show tun0 | grep -q 'inet '"],
                            "interval": "15s", "start_period": "1m0s", "retries": 6},
        })
        args = shlex.split(root.findtext("ExtraParams"))
        self.assertEqual(root.findtext("Privileged"), "true")
        self.assertIn("--sysctl=net.ipv4.conf.all.src_valid_mark=1", args)
        self.assertIn("--health-cmd=ip addr show tun0 | grep -q 'inet '", args)
        self.assertIn("--health-start-period=1m0s", args)
        self.assertIn("--restart=unless-stopped", args)

    def test_masked_credentials_are_preserved_and_xml_escaped(self):
        value = 'example<&"credential'
        root = self.render({"environment": {"TOKEN": value}},
                           {"environment": {"TOKEN": "${TOKEN}"}})
        node = root.find("Config")
        self.assertEqual(node.attrib["Mask"], "true")
        self.assertEqual(node.attrib["Default"], "")
        self.assertEqual(node.text, value)

    def test_mount_modes_and_devices_survive(self):
        root = self.render({"volumes": [{"type": "bind", "source": "/data", "target": "/config", "read_only": True}],
                            "devices": [{"source": "/dev/dri", "target": "/dev/dri", "permissions": "rwm"}]})
        path, device = root.findall("Config")
        self.assertEqual((path.attrib["Mode"], path.text), ("ro", "/data"))
        self.assertEqual((device.attrib["Type"], device.text), ("Device", "/dev/dri:/dev/dri"))

    def test_entrypoint_tty_and_tmpfs_survive(self):
        root = self.render({"entrypoint": ["sh"], "tty": True, "stdin_open": True, "tmpfs": ["/transcode"]})
        args = shlex.split(root.findtext("ExtraParams"))
        for arg in ["--entrypoint=sh", "--tty", "--interactive", "--tmpfs=/transcode"]:
            self.assertIn(arg, args)

    def test_gui_recreation_does_not_claim_compose_ownership(self):
        root = self.render({"labels": {"net.unraid.docker.managed": "dockerman", "com.docker.compose.project": "old"}})
        self.assertEqual([node.attrib["Target"] for node in root.findall("Config")], ["net.unraid.docker.managed"])


if __name__ == "__main__":
    unittest.main()
