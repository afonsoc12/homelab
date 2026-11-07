# LAN ingress migration inventory

The migration uses standard Ingress resources and Authentik proxy providers where the application and its namespace-local outpost support them. Cloudflare hostnames and policies are unchanged; migrated tunnel origins now target Contour.

| App | Namespace | Handling |
| --- | --- | --- |
| adguard | homelab | Authentik proxy; explicit administrator access |
| airflow | addons | Authentik proxy; explicit administrator access |
| alertmanager | monitoring | Authentik proxy; outpost-owned standard Ingress |
| argocd | addons | Existing native Authentik OIDC; standard chart Ingress |
| authelia | ingress | Contour; legacy portal retained pending identity-service retirement |
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
| kopia | homelab | Contour TCP TLS passthrough; native Kopia authentication; upstream currently unreachable |
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
| paperless | homelab | Authentik proxy; explicit administrator access |
| plex | homelab | Contour Ingress; native Plex authentication retained for media clients |
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
| unifi | homelab | Contour and isolated Authentik proxy; explicit upstream CA and hostname verification |
| wealthfolio | homelab | Authentik proxy; explicit administrator access |
| wedding-site | homelab | Authentik proxy; explicit administrator access |
| wireguard | ingress | Authentik proxy; explicit administrator access |
| wled-kitchen | homelab | Authentik proxy; explicit administrator access |
| uptime-kuma | monitoring | Dedicated Authentik proxy owns the Contour Ingress with the existing public certificate |
| wallabag | homelab | Authentik proxy; explicit administrator access |

Home Assistant is routed through the automation Authentik outpost. Its native API and login endpoints bypass the proxy so Home Assistant clients can authenticate with Home Assistant credentials; Home Assistant enforces authentication on those endpoints. Browser access requires Authentik.

Kopia uses Contour TCP TLS passthrough because its native gRPC clients cannot complete browser SSO. Its clients must trust the native Kopia server certificate. The old Nginx controller did not enable TLS passthrough, despite the annotation, so client certificate trust must be checked when the upstream is reachable. Kopia currently times out from the cluster and was not verified end to end. Plex retains native token authentication so media clients continue to work.

UniFi uses an isolated Authentik outpost with its upstream certificate stored in SOPS and mounted as an explicit trust root. TLS validation remains enabled; an encrypted hostname alias matches the upstream certificate SAN without looping through the public ingress. Certificate changes require updating the encrypted trust certificate. This trust is not added to other app proxies.

Uptime Kuma uses its own Authentik outpost because the monitoring wildcard certificate does not cover its public hostname. Its existing public certificate and administrator access binding are retained. The chart relinquishes Ingress ownership to this outpost.

The Kopia, UniFi, status, and Unraid DNS rewrites target Contour. The previously merged stocks rewrite is also reconciled away from the legacy address. The remaining tunnel origins also target Contour. Apply the reviewed Authentik configuration alongside the ArgoCD cutover, then apply DNS and tunnel plans and verify routes before removing Nginx. These final four route changes are prepared in Git; they are not yet verified in the live cluster.

LAN origin alone does not grant anonymous access. Native app authentication and account links are retained; API bypasses require verification.
