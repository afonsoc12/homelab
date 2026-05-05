---
paths:
  - "docs/**"
---
# Documentation Rules

Keep docs under `docs/` in sync when changing the areas they cover.

- Services catalogue: `@docs/services/` — one file per namespace
- Never leak IPs, hostnames, or credentials in docs
- Service entries follow this pattern:
  - Heading icon from `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/<name>.png` or `https://cdn.jsdelivr.net/gh/selfhst/icons/png/<name>.png`
  - Server line uses inline icon: `<img src="https://cdn.simpleicons.org/<icon>" style="height:1em;vertical-align:middle;margin-right:4px">`
  - k3s services: k3s icon + namespace in code tag
  - Bare-metal Pi: Raspberry Pi icon (`cdn.simpleicons.org/raspberrypi`) + `· bare metal`
  - ESP32/WLED: Espressif icon (`cdn.simpleicons.org/espressif`) + `· bare metal`
- Never include raw IPs in docs — they belong in SOPS secrets only
