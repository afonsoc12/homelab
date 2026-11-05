# LAN ingress migration inventory

The migration uses standard Ingress resources and Authentik proxy providers. Existing public tunnel routes remain unchanged.

| App | Namespace | Handling |
| --- | --- | --- |
| adguard | homelab | Authentik proxy; explicit administrator access |
| airflow | addons | Authentik proxy; explicit administrator access |
| alertmanager | monitoring | Authentik proxy; outpost-owned standard Ingress |
| argocd | addons | Existing native Authentik OIDC; standard chart Ingress |
| bambuddy | homelab | Authentik proxy; explicit administrator access |
| bazarr | homelab | Authentik proxy; explicit administrator access |
| bentopdf | homelab | Authentik proxy; explicit administrator access |
| booklore | homelab | Authentik proxy; explicit administrator access |
| changedetection | homelab | Authentik proxy; explicit administrator access |
| cookistash | homelab | Authentik proxy; explicit administrator access |
| decide | homelab | Authentik proxy; explicit administrator access |
| docuseal | homelab | Authentik proxy; explicit administrator access |
| forgejo | devops | Existing native authentication |
| glance | homelab | Authentik proxy; explicit administrator access |
| grocy | automation | Authentik proxy; explicit administrator access |
| hyperion | homelab | Authentik proxy; explicit administrator access |
| kopia | homelab | Unchanged: original nginx authentication retained |
| krusader | homelab | Authentik proxy; explicit administrator access |
| lidarr | homelab | Authentik proxy; explicit administrator access |
| lldap | ingress | Authentik proxy; explicit administrator access |
| longhorn | longhorn-system | Authentik proxy; outpost-owned standard Ingress |
| mealie | homelab | Existing native Authentik OIDC |
| music-assistant | automation | Authentik proxy; explicit administrator access |
| n8n | automation | Authentik proxy; explicit administrator access |
| navidrome | homelab | Authentik proxy; explicit administrator access |
| node-red | automation | Authentik proxy; explicit administrator access |
| ntfy | monitoring | Authentik proxy; outpost-owned standard Ingress |
| octo-track | monitoring | Authentik proxy; outpost-owned standard Ingress |
| paperless | homelab | Authentik proxy; explicit administrator access |
| prometheus | monitoring | Authentik proxy; outpost-owned standard Ingress |
| prowlarr | homelab | Authentik proxy; explicit administrator access |
| qbittorrent | homelab | Authentik proxy; explicit administrator access |
| radarr | homelab | Authentik proxy; explicit administrator access |
| radarr-4k | homelab | Authentik proxy; explicit administrator access |
| scrutiny | homelab | Authentik proxy; explicit administrator access |
| sonarr | homelab | Authentik proxy; explicit administrator access |
| tautulli | homelab | Authentik proxy; explicit administrator access |
| tdarr | homelab | Authentik proxy; explicit administrator access |
| tracktor | homelab | Authentik proxy; explicit administrator access |
| unifi | homelab | Unchanged: original nginx authentication retained |
| wealthfolio | homelab | Authentik proxy; explicit administrator access |
| wedding-site | homelab | Authentik proxy; explicit administrator access |
| wireguard | ingress | Authentik proxy; explicit administrator access |
| wled-kitchen | homelab | Authentik proxy; explicit administrator access |

Kopia and UniFi remain on their existing protected routes pending the gRPC integration and upstream certificate-trust work. The standalone sandbox remains outside the migration.

The existing local DNS wildcard changes to Contour. Only those retained legacy routes have DNS exceptions.

LAN origin alone does not grant anonymous access. Native app authentication and account links are retained; API bypasses require verification.
