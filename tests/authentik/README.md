# Authentik policy checks

Run from the repository root with Python and PyYAML installed:

```sh
python3 -m unittest discover -s tests/authentik -v
```

These tests exercise the inline Terraform policy expressions, stage ordering,
and the compatibility patch against a pinned upstream fixture. They do not
perform a browser login, redeem a real Plex token, or run Authentik's database
and invitation lifecycle. A passing suite does not establish that the deployed
integration works end to end.
