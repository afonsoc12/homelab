# LAN ingress migration inventory

The migration uses standard Ingress resources and Authentik proxy providers where the application and its namespace-local outpost support them. Cloudflare hostnames and policies are unchanged; migrated tunnel origins now target Contour.

| App | Namespace | Handling |
| --- | --- | --- |
| adguard | homelab | Authentik proxy; explicit administrator access |
| airflow | addons | Authentik proxy; explicit administrator access |
| alertmanager | monitoring | Authentik proxy; outpost-owned standard Ingress |
| argocd | addons | Existing native Authentik OIDC; standard chart Ingress |
| authelia | ingress | Contour; legacy login portal retained temporarily for UniFi |
| bambuddy | homelab | Authentik proxy; explicit administrator access |
| bazarr | homelab | Authentik proxy; explicit administrator access |
| bentopdf | homelab | Authentik proxy; explicit administrator access |
| booklore | homelab | Authentik proxy; explicit administrator access |
| calibre-web | homelab | Authentik proxy; explicit administrator access |
| changedetection | homelab | Authentik proxy; explicit administrator access |
| cookistash | homelab | Authentik proxy; explicit administrator access |
| decide | homelab | Authentik proxy; explicit administrator access |
| docuseal | homelab | Authentik proxy; explicit administrator access |
| forgejo | devops | Existing native authentication |
| freshrss | homelab | Authentik proxy; explicit administrator access |
| glance | homelab | Authentik proxy; explicit administrator access |
| grocy | automation | Authentik proxy; explicit administrator access |
| home-assistant | automation | Authentik proxy; native authenticated API paths remain available to integrations |
| hyperion | homelab | Authentik proxy; explicit administrator access |
| kopia | homelab | Unchanged: nginx TLS/gRPC passthrough; authentication path needs verification |
| krusader | homelab | Authentik proxy; explicit administrator access |
| lidarr | homelab | Authentik proxy; explicit administrator access |
| lldap | ingress | Authentik proxy; explicit administrator access |
| longhorn | longhorn-system | Authentik proxy; outpost-owned standard Ingress |
| mealie | homelab | Existing native Authentik OIDC |
| music-assistant | automation | Authentik proxy; explicit administrator access |
| music-assistant-alexa-skill | automation | Authentik proxy; explicit administrator access |
| music-assistant-stream | automation | Authentik proxy; explicit administrator access |
| n8n | automation | Authentik proxy; explicit administrator access |
| navidrome | homelab | Authentik proxy; explicit administrator access |
| node-red | automation | Authentik proxy; explicit administrator access |
| ntfy | monitoring | Authentik proxy; outpost-owned standard Ingress |
| octo-track | monitoring | Authentik proxy; outpost-owned standard Ingress |
| ollama | sandbox | Live route is unmanaged by ArgoCD; adoption and Authentik routing are still required |
| paperless | homelab | Authentik proxy; explicit administrator access |
| plex | homelab | Unchanged: native Plex authentication and non-tunnel ingress |
| prometheus | monitoring | Authentik proxy; outpost-owned standard Ingress |
| prowlarr | homelab | Authentik proxy; explicit administrator access |
| qbittorrent | homelab | Authentik proxy; explicit administrator access |
| radarr | homelab | Authentik proxy; explicit administrator access |
| radarr-4k | homelab | Authentik proxy; explicit administrator access |
| scrutiny | homelab | Authentik proxy; explicit administrator access |
| seerr | homelab | Authentik proxy; explicit administrator access |
| sonarr | homelab | Authentik proxy; explicit administrator access |
| spliit | homelab | Authentik proxy; explicit administrator access |
| tautulli | homelab | Authentik proxy; explicit administrator access |
| tdarr | homelab | Authentik proxy; explicit administrator access |
| tracktor | homelab | Authentik proxy; explicit administrator access |
| unraid | homelab | Authentik proxy; explicit administrator access |
| unifi | homelab | Unchanged: original nginx authentication retained |
| wealthfolio | homelab | Authentik proxy; explicit administrator access |
| wedding-site | homelab | Authentik proxy; explicit administrator access |
| wireguard | ingress | Authentik proxy; explicit administrator access |
| wled-kitchen | homelab | Authentik proxy; explicit administrator access |
| uptime-kuma | monitoring | Authentik forward auth retained on nginx; Contour migration needs a per-app route and matching public certificate |
| wallabag | homelab | Authentik proxy; explicit administrator access |

Home Assistant is routed through the automation Authentik outpost. Its native API and login endpoints bypass the proxy so Home Assistant clients can authenticate with Home Assistant credentials; Home Assistant enforces authentication on those endpoints. Browser access requires Authentik.

Kopia remains on nginx for TLS/gRPC passthrough while its supported authentication path is verified; the current Authelia annotation is ineffective with passthrough. UniFi remains on its existing route until its upstream certificate can be validated. Uptime Kuma remains on nginx with Authentik forward auth because its public host needs a distinct Contour route and certificate. The standalone sandbox route remains outside this outpost migration.

The existing local DNS wildcard changes to Contour. Kopia, UniFi, and Ollama retain their existing DNS exceptions.

LAN origin alone does not grant anonymous access. Native app authentication and account links are retained; API bypasses require verification.
