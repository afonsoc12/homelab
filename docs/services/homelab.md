# Homelab

Self-hosted productivity, finance, media, and utility apps.

Services here run in two places:

- **Kubernetes** (`homelab` namespace) — managed by ArgoCD
- **Docker on `hoarder`** ([homelab-stackz](https://github.com/afonsoc12/homelab-stackz)) — exposed to the cluster via `external-ingress`

---

## Kubernetes

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gitea.png" class="svc-icon"> Gitea

Self-hosted Git service. Mirrors and hosts private repositories, acts as a local fallback for GitHub-dependent workflows.

[:octicons-book-16: Documentation](https://docs.gitea.com/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/gitea/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/mealie.png" class="svc-icon"> Mealie

Recipe manager and meal planner. Supports import from any URL, nutritional data, and shopping list generation.

[:octicons-book-16: Documentation](https://docs.mealie.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/mealie/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/ghostfolio.png" class="svc-icon"> Ghostfolio

Open-source wealth management. Tracks investment portfolios across brokers and asset classes with live market data.

[:octicons-book-16: Documentation](https://ghostfol.io/en/blog/2021/07/ghostfolio-meets-self-hosting) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/ghostfolio/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/firefly-iii.png" class="svc-icon"> Firefly III

Personal finance manager. Tracks income, expenses, and budgets with full double-entry bookkeeping.

[:octicons-book-16: Documentation](https://docs.firefly-iii.org/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/firefly/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/freshrss.png" class="svc-icon"> FreshRSS

Self-hosted RSS aggregator. Consolidates feeds from blogs, news sites, and podcasts into a single interface.

[:octicons-book-16: Documentation](https://freshrss.github.io/FreshRSS/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/freshrss/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/glance.png" class="svc-icon"> Glance

Personalised dashboard. Shows RSS feeds, weather, stocks, server stats, and other widgets in a single-page layout.

[:octicons-book-16: Documentation](https://github.com/glanceapp/glance) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/glance/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/romm.png" class="svc-icon"> RomM

ROM and game library manager. Organises and serves a local game collection with metadata and cover art from IGDB.

[:octicons-book-16: Documentation](https://romm.app/docs) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/romm/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/wallabag.png" class="svc-icon"> Wallabag

Read-it-later service. Saves articles for offline reading, strips ads, and syncs with mobile apps.

[:octicons-book-16: Documentation](https://doc.wallabag.org/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/wallabag/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/stirling-pdf.png" class="svc-icon"> Stirling PDF

Self-hosted PDF toolbox. Merge, split, compress, convert, rotate, and watermark PDFs without sending files to third-party services.

[:octicons-book-16: Documentation](https://docs.stirlingpdf.com/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/stirling-pdf/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/changedetection.png" class="svc-icon"> ChangeDetection

Monitors web pages for changes and sends notifications. Used for tracking price changes, availability alerts, and content updates.

[:octicons-book-16: Documentation](https://changedetection.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/changedetection/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/docuseal.png" class="svc-icon"> Docuseal

Self-hosted document signing platform. Creates, distributes, and collects signatures on PDF forms.

[:octicons-book-16: Documentation](https://www.docuseal.co/docs) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/docuseal/values.yaml)

---

## Docker on `hoarder`

These services run as Docker containers on the `hoarder` NAS via [homelab-stackz](https://github.com/afonsoc12/homelab-stackz). They are exposed through the cluster's ingress-nginx via `external-ingress` rules.

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/docker.png" class="svc-icon"> Backup Utils

Utility container for backup and data-maintenance tasks on Unraid.

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/navidrome.png" class="svc-icon"> Navidrome

Personal music streaming server for self-hosted audio libraries.

[:octicons-book-16: Documentation](https://www.navidrome.org/docs/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tdarr.png" class="svc-icon"> Tdarr

Distributed media transcoding and health-check automation for video libraries.

[:octicons-book-16: Documentation](https://docs.tdarr.io/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/portainer.png" class="svc-icon"> Portainer CE

Container management UI for Docker environments.

[:octicons-book-16: Documentation](https://docs.portainer.io/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/scrutiny.png" class="svc-icon"> Scrutiny

Disk S.M.A.R.T. monitoring dashboard with historical metrics and alerts.

[:octicons-book-16: Documentation](https://github.com/AnalogJ/scrutiny)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/github.png" class="svc-icon"> Ghorg

Bulk Git repository cloning and synchronization tool.

[:octicons-book-16: Documentation](https://github.com/gabrie30/ghorg)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/krusader.png" class="svc-icon"> Krusader

Dual-pane file manager used for direct filesystem operations on the NAS.

[:octicons-book-16: Documentation](https://krusader.org/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bookstack.png" class="svc-icon"> BookLore

Self-hosted e-book and reading library service.

[:octicons-book-16: Documentation](https://github.com/adityachandelgit/booklore)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/plex.png" class="svc-icon"> Plex

Media server. Streams movies, TV shows, and music to all devices on the network and remotely.

[:octicons-book-16: Documentation](https://support.plex.tv/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/plex/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/sonarr.png" class="svc-icon"> Sonarr

TV series collection manager. Monitors RSS feeds, grabs releases automatically, and sends them to qBittorrent.

[:octicons-book-16: Documentation](https://wiki.servarr.com/sonarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/sonarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/radarr.png" class="svc-icon"> Radarr

Movie collection manager. Same as Sonarr but for movies.

[:octicons-book-16: Documentation](https://wiki.servarr.com/radarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/radarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/radarr-4k.png" class="svc-icon"> Radarr 4K

Separate Radarr instance dedicated to 4K/UHD movie quality profiles.

[:octicons-book-16: Documentation](https://wiki.servarr.com/radarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/radarr-4k/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bazarr.png" class="svc-icon"> Bazarr

Subtitle manager. Automatically downloads subtitles for movies and TV shows managed by Sonarr/Radarr.

[:octicons-book-16: Documentation](https://wiki.bazarr.media/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/bazarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lidarr.png" class="svc-icon"> Lidarr

Music collection manager. Monitors and automatically grabs music releases.

[:octicons-book-16: Documentation](https://wiki.servarr.com/lidarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/lidarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/prowlarr.png" class="svc-icon"> Prowlarr

Indexer manager. Centralises and syncs indexer configuration across Sonarr, Radarr, Lidarr, and other \*arr apps.

[:octicons-book-16: Documentation](https://wiki.servarr.com/prowlarr) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/prowlarr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/qbittorrent.png" class="svc-icon"> qBittorrent

BitTorrent client. Receives download tasks from the \*arr stack and saves completed files to the media library.

[:octicons-book-16: Documentation](https://github.com/qbittorrent/qBittorrent/wiki) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/qbittorrent/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/privoxy.png" class="svc-icon"> PrivoxyVPN

VPN gateway and shared network stack for downloader and \*arr containers.

[:octicons-book-16: Documentation](https://github.com/binhex/arch-privoxyvpn)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/seerr.png" class="svc-icon"> Overseerr / Seerr

Media request management. Lets users browse and request movies and TV shows, which are then routed to Radarr/Sonarr.

[:octicons-book-16: Documentation](https://docs.overseerr.dev/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/seerr/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tautulli.png" class="svc-icon"> Tautulli

Plex monitoring and analytics. Tracks play history, sends notifications, and provides usage statistics.

[:octicons-book-16: Documentation](https://tautulli.com/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/tautulli/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kometa.png" class="svc-icon"> Kometa

Plex metadata and collection automation tool (formerly Plex Meta Manager).

[:octicons-book-16: Documentation](https://kometa.wiki/)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/calibre-web.png" class="svc-icon"> Calibre Web

Web interface for a Calibre e-book library. Browse, read, and download books from any browser or e-reader.

[:octicons-book-16: Documentation](https://github.com/janeczku/calibre-web) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/calibre-web/values.yaml)
