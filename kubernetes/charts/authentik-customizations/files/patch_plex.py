"""Minimal, version-checked compatibility patch for the pinned Plex source.

The owner is allowed by the native source, even when Plex's friends API is
retired. Never treat a failed friendship lookup as permission for other users.
"""

from pathlib import Path


def patch(source: str) -> str:
    old = '\n        owner_friends = self.get_friends()\n'
    new = '''
        # Owner access does not depend on the retired friends API.
        if owner_id == user_ident:
            return True
        try:
            owner_friends = self.get_friends()
        except RequestException:
            LOGGER.warning("Plex friendship lookup unavailable; denying friend-only access")
            return False
'''
    if source.count(old) != 1:
        raise RuntimeError("Plex source changed; review the compatibility patch before upgrading")
    return source.replace(old, new)


if __name__ == "__main__":
    source = Path("/authentik/sources/plex/plex.py").read_text()
    result = patch(source)
    compile(result, "plex.py", "exec")
    Path("/customization-runtime/plex.py").write_text(result)
