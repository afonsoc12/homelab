# Namespaces & Apps

## Namespace Overview

| Namespace | Purpose |
|-----------|---------|
| `addons` | Cluster infrastructure (ArgoCD, cert-manager, MetalLB, Reflector) |
| `automation` | Home automation stack |
| `databases` | Shared database services |
| `homelab` | Self-hosted productivity and media apps |
| `ingress` | External access layer |
| `longhorn-system` | Distributed storage |
| `monitoring` | Observability stack |
| `sandbox` | Experimental apps (not production) |

---

## `addons` — Cluster Infrastructure

| App | Chart | Description |
|-----|-------|-------------|
| ArgoCD | `argo/argo-cd` | GitOps controller |
| cert-manager | `jetstack/cert-manager` | TLS certificate automation |
| cert-manager-resources | local | ClusterIssuers, Certificates |
| MetalLB | `metallb/metallb` | Bare-metal load balancer |
| metallb-resources | local | IPAddressPools, L2Advertisements |
| Reflector | `emberstack/reflector` | Secret/ConfigMap cross-namespace sync |

---

## `automation` — Home Automation

| App | Description |
|-----|-------------|
| [Home Assistant](https://www.home-assistant.io/) | Central home automation hub |
| [ESPHome](https://esphome.io/) | Firmware and OTA for ESP-based devices |
| [Zigbee2MQTT](https://www.zigbee2mqtt.io/) | Zigbee coordinator → MQTT bridge |
| [Mosquitto](https://mosquitto.org/) | MQTT broker |
| [Node-RED](https://nodered.org/) | Visual flow-based automation |
| [n8n](https://n8n.io/) | Workflow automation |
| [Govee2MQTT](https://github.com/wez/govee2mqtt) | Govee smart light integration |
| [Grocy](https://grocy.info/) | Household management (groceries, chores) |
| [Piper](https://github.com/rhasspy/piper) | Local text-to-speech |
| [Whisper](https://github.com/openai/whisper) | Local speech-to-text |

---

## `databases` — Shared Databases

| App | Description |
|-----|-------------|
| PostgreSQL | Primary relational DB (shared across apps) |
| MariaDB | MySQL-compatible DB |
| Redis | In-memory cache / message broker |
| InfluxDB | Time-series DB (metrics, sensors) |

---

## `homelab` — Self-Hosted Apps

| App | Description |
|-----|-------------|
| [Mealie](https://mealie.io/) | Recipe manager and meal planner |
| [Ghostfolio](https://ghostfol.io/) | Open-source wealth management |
| [Firefly III](https://www.firefly-iii.org/) | Personal finance manager |
| [FreshRSS](https://freshrss.org/) | RSS feed aggregator |
| [Glance](https://github.com/glanceapp/glance) | Personal dashboard |
| [Wallabag](https://wallabag.org/) | Read-it-later service |
| [BentoPDF](https://github.com/Alamino/BentoPDF) | PDF editing and conversion |
| [ChangeDetection](https://changedetection.io/) | Web page change monitoring |
| [Docuseal](https://docuseal.co/) | Document signing |

---

## `ingress` — Access & Security

| App | Description |
|-----|-------------|
| [Authentik](https://goauthentik.io/) | Identity provider (IdP) |
| [Authelia](https://www.authelia.com/) | SSO / 2FA proxy (being decommissioned) |
| [LLDAP](https://github.com/lldap/lldap) | Lightweight LDAP server |
| [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) | Ingress controller |
| [Cloudflared](https://github.com/cloudflare/cloudflared) | Cloudflare Tunnel daemon |
| Cloudflare DDNS | Dynamic DNS updater (PT + UK zones) |
| [Wireguard](https://www.wireguard.com/) | VPN server |

---

## `monitoring` — Observability

| App | Description |
|-----|-------------|
| [Grafana](https://grafana.com/) | Dashboards and visualisation |
| [Prometheus Stack](https://github.com/prometheus-community/helm-charts) | Prometheus + Alertmanager + kube-state-metrics |
| [Loki](https://grafana.com/oss/loki/) | Log aggregation |
| [Alloy](https://grafana.com/oss/alloy-opentelemetry-collector/) | OpenTelemetry collector / agent |
| [Uptime Kuma](https://uptime.kuma.pet/) | Service uptime monitoring |
| [ntfy](https://ntfy.sh/) | Push notification server |
| Speedtest Exporter | Internet speed Prometheus exporter |
| Unpoller | UniFi metrics exporter |
| Cluster Heartbeat | Custom heartbeat check |
