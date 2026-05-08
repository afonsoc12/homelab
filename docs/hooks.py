import os


def on_config(config):
    version = os.environ.get("DOCS_VERSION", "")
    if not version:
        return config
    repo_url = (config.get("repo_url") or "").rstrip("/")
    releases_url = f"{repo_url}/releases/tag/v{version.replace('+', '%2B')}"
    existing = config.get("copyright") or ""
    config["copyright"] = (
        f'{existing}'
        f'<span id="docs-version-meta" data-version="v{version}" data-url="{releases_url}" hidden></span>'
    )
    js = config.setdefault("extra_javascript", [])
    if "assets/version.js" not in js:
        js.append("assets/version.js")
    return config
