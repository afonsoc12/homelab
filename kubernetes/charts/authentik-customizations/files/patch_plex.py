"""Minimal, version-checked compatibility patch for the pinned Plex source.

The owner is allowed without a friends lookup. On HTTP 410, use Plex's legacy
connected-users endpoint; unknown users and failed lookups remain denied.
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
    source = source.replace(old, new)
    old_friends = '''        response.raise_for_status()
        return response.json()

    def get_user_info'''
    new_friends = '''        if response.status_code == 410:
            # This is the accepted connected-user list, not pending invites.
            # Use only independently named accounts; exclude managed profiles.
            from xml.etree.ElementTree import fromstring, ParseError

            response = self._session.get(
                response.url.replace("/api/v2/friends", "/api/users"),
                headers={"Accept": "application/xml"},
            )
            response.raise_for_status()
            if len(response.content) > 2_000_000 or any(
                marker in response.content for marker in (b"<!DOCTYPE", b"<!ENTITY")
            ):
                return []
            try:
                root = fromstring(response.content)
            except ParseError:
                return []
            if root.tag != "MediaContainer":
                return []
            return [
                {"id": entry.attrib["id"]}
                for entry in root.findall("User")
                if entry.attrib.get("id", "").isdecimal()
                and entry.attrib.get("username")
                and entry.attrib.get("restricted", "0") != "1"
            ]
        response.raise_for_status()
        return response.json()

    def get_user_info'''
    if source.count(old_friends) != 1:
        raise RuntimeError("Plex friends method changed; review the compatibility patch")
    return source.replace(old_friends, new_friends)


if __name__ == "__main__":
    source = Path("/authentik/sources/plex/plex.py").read_text()
    result = patch(source)
    compile(result, "plex.py", "exec")
    Path("/customization-runtime/plex.py").write_text(result)
