"""Rename an explicitly selected default administrator through FAB's user API."""

import argparse
import json
import os


def rename_admin(spec, *, apply=False):
    from airflow.providers.fab.auth_manager.cli_commands.utils import get_application_builder

    if set(spec) != {"id", "from", "to"}:
        raise ValueError("Rename requires an existing ID, source username and target username")
    if not isinstance(spec["id"], int) or not all(isinstance(spec[k], str) and spec[k] for k in ("from", "to")):
        raise ValueError("Invalid account rename")
    if spec["from"] == spec["to"]:
        raise ValueError("Source and target usernames must differ")
    with get_application_builder() as appbuilder:
        manager = appbuilder.sm
        source = manager.find_user(username=spec["from"])
        target = manager.find_user(username=spec["to"])
        if source is None and target is not None and target.id == spec["id"]:
            if not target.active or "Admin" not in {role.name for role in target.roles}:
                raise ValueError("Renamed owner must remain an active administrator")
            return "already-renamed"
        if source is None or source.id != spec["id"] or target is not None:
            raise ValueError("Account identity differs from the reviewed rename")
        roles = {role.name for role in source.roles}
        if not source.active or "Admin" not in roles:
            raise ValueError("The selected owner must be an existing active administrator")
        if not apply:
            return "ready"
        source.username = spec["to"]
        if not manager.update_user(source):
            raise RuntimeError("FAB rejected the account rename")
        renamed = manager.find_user(username=spec["to"])
        if renamed is None or renamed.id != spec["id"] or {role.name for role in renamed.roles} != roles:
            raise RuntimeError("Renamed account identity or roles differ")
        if manager.find_user(username=spec["from"]) is not None:
            raise RuntimeError("The previous default administrator still exists")
        return "renamed"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Apply the reviewed rename; defaults to a dry run")
    args = parser.parse_args()
    spec = json.loads(os.environ["AIRFLOW_OIDC_ACCOUNT_RENAME"])
    print("Owner account migration:", rename_admin(spec, apply=args.apply))


if __name__ == "__main__":
    main()
