"""Check SOPS protection without decrypting or printing any values."""

from pathlib import Path
import re
import subprocess
import sys

import yaml


def unencrypted_paths(value, pattern, path=(), protected=False):
    if isinstance(value, dict):
        for key, child in value.items():
            if not path and key == "sops":
                continue
            selected = protected or pattern is None or bool(pattern.search(str(key)))
            yield from unencrypted_paths(child, pattern, (*path, str(key)), selected)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from unencrypted_paths(child, pattern, (*path, str(index)), protected)
    elif protected and value is not None:
        if not isinstance(value, str) or not value.startswith("ENC[AES256_GCM,"):
            yield ".".join(path)


def main():
    files = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"], text=True
    ).splitlines()
    errors = []
    checked = 0
    for name in sorted(set(files)):
        path = Path(name)
        if name == ".sops.yaml" or not re.search(r"\.sops\.ya?ml$", name):
            continue
        if not path.is_file():
            continue
        try:
            data = yaml.safe_load(path.read_text())
            metadata = data["sops"]
            if not str(metadata.get("mac", "")).startswith("ENC[AES256_GCM,"):
                errors.append(f"{name}: missing encrypted MAC")
            pattern = re.compile(metadata["encrypted_regex"]) if "encrypted_regex" in metadata else None
            errors.extend(f"{name}: unencrypted protected field {key}" for key in unencrypted_paths(data, pattern))
            checked += 1
        except (KeyError, TypeError, ValueError, yaml.YAMLError, re.error):
            errors.append(f"{name}: invalid SOPS metadata or YAML (values suppressed)")
    for error in errors:
        print(error, file=sys.stderr)
    print(f"SOPS check: {checked} files, {len(errors)} errors")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
