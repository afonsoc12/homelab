# Media & Entertainment

Media server, download automation, request management, and music streaming.

All services run on **hoarder** (Docker), managed via the Unraid UI. Download apps share a VPN network stack via PrivoxyVPN.

---

## Media Server

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/plex.png" class="svc-icon"> Plex

*hoarder · Docker*

Media server. Streams movies, TV shows, and music to all devices on the network and remotely.

[:octicons-book-16: Documentation](https://support.plex.tv/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/plex/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tautulli.png" class="svc-icon"> Tautulli

*hoarder · Docker*

Plex monitoring and analytics. Tracks play history, sends notifications, and provides usage statistics.

[:octicons-book-16: Documentation](https://tautulli.com/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/tautulli/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kometa.png" class="svc-icon"> Kometa

*hoarder · Docker*

Plex metadata and collection automation tool (formerly Plex Meta Manager).

[:octicons-book-16: Documentation](https://kometa.wiki/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/seerr.png" class="svc-icon"> Overseerr / Seerr

*hoarder · Docker*

Media request management. Lets users browse and request movies and TV shows, which are then routed to Radarr/Sonarr.

[:octicons-book-16: Documentation](https://docs.overseerr.dev/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/seerr/values.yaml)

---

## Download Automation

All \*arr apps and download clients run inside the PrivoxyVPN network stack.

### PrivoxyVPN

*hoarder · Docker*

VPN gateway and shared network namespace for all downloader and \*arr containers. All traffic from these containers is routed through the VPN.

[:octicons-book-16: Documentation](https://github.com/binhex/arch-privoxyvpn)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/qbittorrent.png" class="svc-icon"> qBittorrent

*hoarder · Docker · via PrivoxyVPN*

BitTorrent client. Receives download tasks from the \*arr stack and saves completed files to the media library.

[:octicons-book-16: Documentation](https://github.com/qbittorrent/qBittorrent/wiki) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/qbittorrent/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/prowlarr.png" class="svc-icon"> Prowlarr

*hoarder · Docker · via PrivoxyVPN*

Indexer manager. Centralises and syncs indexer configuration across Sonarr, Radarr, Lidarr, and other \*arr apps.

[:octicons-book-16: Documentation](https://wiki.servarr.com/prowlarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/prowlarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/sonarr.png" class="svc-icon"> Sonarr

*hoarder · Docker · via PrivoxyVPN*

TV series collection manager. Monitors RSS feeds, grabs releases automatically, and sends them to qBittorrent.

[:octicons-book-16: Documentation](https://wiki.servarr.com/sonarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/sonarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/radarr.png" class="svc-icon"> Radarr

*hoarder · Docker · via PrivoxyVPN*

Movie collection manager.

[:octicons-book-16: Documentation](https://wiki.servarr.com/radarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/radarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/radarr-4k.png" class="svc-icon"> Radarr 4K

*hoarder · Docker · via PrivoxyVPN*

Separate Radarr instance dedicated to 4K/UHD movie quality profiles.

[:octicons-book-16: Documentation](https://wiki.servarr.com/radarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/radarr-4k/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lidarr.png" class="svc-icon"> Lidarr

*hoarder · Docker · via PrivoxyVPN*

Music collection manager. Monitors and automatically grabs music releases.

[:octicons-book-16: Documentation](https://wiki.servarr.com/lidarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/lidarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bazarr.png" class="svc-icon"> Bazarr

*hoarder · Docker · via PrivoxyVPN*

Subtitle manager. Automatically downloads subtitles for movies and TV shows managed by Sonarr/Radarr.

[:octicons-book-16: Documentation](https://wiki.bazarr.media/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/bazarr/values.yaml)

---

## Music

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/navidrome.png" class="svc-icon"> Navidrome

*hoarder · Docker*

Personal music streaming server. Subsonic-compatible API, works with DSub, Symfonium, and other mobile clients.

[:octicons-book-16: Documentation](https://www.navidrome.org/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/navidrome/values.yaml)

---

## Transcoding

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tdarr.png" class="svc-icon"> Tdarr

*hoarder · Docker*

Distributed media transcoding and health-check automation. Converts video files to efficient codecs and validates library integrity.

[:octicons-book-16: Documentation](https://docs.tdarr.io/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/tdarr/values.yaml)
