"""Render DockerMan templates from Docker Compose's normalized configuration."""

import shlex
import xml.etree.ElementTree as ET


def unraid_template(service, source, services, networks, meta, domain=""):
    """Keep DockerMan's native create command equivalent to the Compose service."""
    root = ET.Element("Container", version="2")

    def tag(name, value=""):
        ET.SubElement(root, name).text = str(value)

    def config(kind, target, value, *, name=None, mode="", masked=False, description="", display="always"):
        node = ET.SubElement(root, "Config", {
            "Name": str(name or target), "Target": str(target),
            "Default": "" if masked else str(value), "Mode": str(mode),
            "Description": str(description), "Type": kind, "Display": display,
            "Required": "false", "Mask": str(masked).lower(),
        })
        # Masked credentials still need their current value for GUI Apply/Update.
        # The rendered template lives only on the host, root-readable, never in Git.
        node.text = str(value)

    image = service["image"]
    repository = image.split("@")[0].rsplit(":", 1)[0] if ":" in image.split("@")[0] else image.split("@")[0]
    if repository.startswith("ghcr.io/"):
        owner, *parts = repository.removeprefix("ghcr.io/").split("/")
        registry = f"https://github.com/{owner}/{parts[-1]}/pkgs/container/{parts[-1]}"
    else:
        path = repository.removeprefix("docker.io/")
        registry = "https://hub.docker.com/" + ("r/" if "/" in path else "_/") + path + "/"
    tag("Name", service["container_name"])
    tag("Repository", image)
    tag("Registry", meta.get("registry", registry))
    network = service.get("network_mode")
    if network and network.startswith("service:"):
        network = "container:" + services[network.split(":", 1)[1]]["container_name"]
    if not network:
        attached = list(service.get("networks", {"default": None}))
        if len(attached) != 1:
            raise ValueError("DockerMan templates currently require exactly one network")
        network = networks[attached[0]]["name"]
    tag("Network", network)
    tag("MyIP")
    tag("Privileged", str(service.get("privileged", False)).lower())
    for field, key in [("Support", "support_url"), ("Project", "project_url"),
                       ("Overview", "overview"), ("Category", "category"),
                       ("Icon", "icon"), ("License", "license")]:
        tag(field, meta.get(key, ""))
    webui = (f"https://{meta['ingress_host']}.{domain}/"
             if meta.get("ingress_host") and domain else meta.get("webui", ""))
    tag("WebUI", webui)
    tag("TemplateURL")
    tag("Requires")

    args = []

    def option(key, value):
        args.append("--" + key + "=" + shlex.quote(str(value)))

    option("restart", service.get("restart", "no"))
    for key in ["user", "hostname", "entrypoint"]:
        value = service.get(key)
        if value is not None:
            if isinstance(value, list):
                if len(value) != 1:
                    raise ValueError("DockerMan requires a single entrypoint executable")
                value = value[0]
            option(key, value)
    for key in ["tty", "stdin_open", "read_only", "init"]:
        if service.get(key):
            args.append({"tty": "--tty", "stdin_open": "--interactive",
                         "read_only": "--read-only", "init": "--init"}[key])
    for key, flag in [("cap_add", "cap-add"), ("cap_drop", "cap-drop"),
                      ("security_opt", "security-opt"), ("tmpfs", "tmpfs")]:
        for value in service.get(key, []):
            option(flag, value)
    for key, value in service.get("sysctls", {}).items():
        option("sysctl", f"{key}={value}")
    health = service.get("healthcheck", {})
    test = health.get("test", [])
    if health.get("disable") or test == ["NONE"]:
        args.append("--no-healthcheck")
    elif test:
        option("health-cmd", test[1] if test[0] == "CMD-SHELL" else shlex.join(test[1:]))
        for key in ["interval", "timeout", "start_period", "start_interval", "retries"]:
            if key in health:
                option("health-" + key.replace("_", "-"), health[key])
    tag("ExtraParams", " ".join(args))
    command = service.get("command", [])
    tag("PostArgs", shlex.join(command) if isinstance(command, list) else command)

    for port in service.get("ports", []):
        target = str(port["target"])
        published = str(port.get("published", target))
        if port.get("host_ip"):
            published = port["host_ip"] + ":" + published
        config("Port", target, published, mode=port.get("protocol", "tcp"),
               name=meta.get("port_names", {}).get(target),
               description=meta.get("port_descriptions", {}).get(target, ""))
    for volume in service.get("volumes", []):
        if volume["type"] != "bind":
            raise ValueError("DockerMan templates require bind mounts for persistent data")
        target = volume["target"]
        config("Path", target, volume["source"], mode="ro" if volume.get("read_only") else "rw",
               name=meta.get("volume_names", {}).get(target),
               description=meta.get("volume_descriptions", {}).get(target, ""))
    for device in service.get("devices", []):
        config("Device", device["target"], device["source"] + ":" + device["target"],
               mode=device.get("permissions", "rwm"))
    source_env = source.get("environment", {})
    if isinstance(source_env, list):
        source_env = dict(value.split("=", 1) for value in source_env)
    for key, value in service.get("environment", {}).items():
        masked = key in meta.get("secret_env", []) or "${" in str(source_env.get(key, ""))
        config("Variable", key, "" if value is None else value, masked=masked,
               name=meta.get("env_names", {}).get(key),
               description=meta.get("env_descriptions", {}).get(key, ""),
               display=meta.get("env_display", {}).get(key, "always"))
    # Compose ownership labels must not survive GUI recreation: Compose needs to
    # detect the native container as a migration, rather than trusting an old hash.
    for key, value in service.get("labels", {}).items():
        if not key.startswith("com.docker.compose."):
            config("Label", key, value)
    ET.indent(root, space="  ")
    return '<?xml version="1.0"?>\n' + ET.tostring(root, encoding="unicode") + "\n"


class FilterModule:
    def filters(self):
        return {"unraid_template": unraid_template}
