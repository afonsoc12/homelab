# LAN ingress migration inventory

Public tunnel routes are unchanged. Standalone sandbox manifests and applications with public tunnel endpoints, including Forgejo and Music Assistant, remain outside this migration.

| App | Namespace | Access handling |
| --- | --- | --- |
| airflow | addons | Existing trusted-network bypass |
| grocy | automation | Existing trusted-network bypass |
| n8n | automation | Existing trusted-network bypass |
| node-red | automation | Existing trusted-network bypass |
| bambuddy | homelab | Existing trusted-network bypass |
| bentopdf | homelab | Existing native authentication or bypass |
| changedetection | homelab | Existing trusted-network bypass |
| cookistash | homelab | Existing trusted-network bypass |
| docuseal | homelab | Existing trusted-network bypass |
| adguard | homelab | Existing trusted-network bypass |
| bazarr | homelab | Existing trusted-network bypass |
| booklore | homelab | Existing trusted-network bypass |
| decide | homelab | Existing trusted-network bypass |
| hyperion | homelab | Existing trusted-network bypass |
| kopia | homelab | Authentik forward auth; HTTP/2 upstream |
| krusader | homelab | Existing trusted-network bypass |
| lidarr | homelab | Existing trusted-network bypass |
| navidrome | homelab | Existing trusted-network bypass |
| prowlarr | homelab | Existing trusted-network bypass |
| qbittorrent | homelab | Existing trusted-network bypass |
| radarr | homelab | Existing trusted-network bypass |
| radarr-4k | homelab | Existing trusted-network bypass |
| scrutiny | homelab | Existing trusted-network bypass |
| sonarr | homelab | Existing trusted-network bypass |
| tautulli | homelab | Existing trusted-network bypass |
| tdarr | homelab | Existing trusted-network bypass |
| unifi | homelab | Authentik proxy with existing network restriction |
| wled-kitchen | homelab | Existing trusted-network bypass |
| glance | homelab | Existing trusted-network bypass and protected path exceptions |
| mealie | homelab | Existing trusted-network bypass |
| paperless | homelab | Existing trusted-network bypass |
| tracktor | homelab | Existing trusted-network bypass |
| wealthfolio | homelab | Existing trusted-network bypass |
| wedding-site | homelab | Existing native authentication or bypass |
| lldap | ingress | Authentik proxy with existing network restriction |
| wireguard | ingress | Existing trusted-network bypass |
| ntfy | monitoring | Existing trusted-network bypass |
| octo-track | monitoring | Existing trusted-network bypass |
| argocd | addons | Native Authentik OIDC; standard Ingress with HTTPS/gRPC |
| prometheus-stack | monitoring | Existing trusted-network bypass |
| longhorn | longhorn-system | Authentik proxy |
