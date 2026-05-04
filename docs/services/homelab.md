# Productivity & Finance

Self-hosted apps for personal, household, and financial use.

---

## Productivity

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/mealie.png" class="svc-icon"> Mealie

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Recipe manager and meal planner. Supports import from any URL, nutritional data, and shopping list generation.

[:octicons-book-16: Documentation](https://docs.mealie.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/mealie/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/freshrss.png" class="svc-icon"> FreshRSS

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Self-hosted RSS aggregator. Consolidates feeds from blogs, news sites, and podcasts into a single interface.

[:octicons-book-16: Documentation](https://freshrss.github.io/FreshRSS/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/freshrss/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/glance.png" class="svc-icon"> Glance

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Personalised dashboard. Shows RSS feeds, weather, stocks, server stats, and other widgets in a single-page layout.

[:octicons-book-16: Documentation](https://github.com/glanceapp/glance) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/glance/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/wallabag.png" class="svc-icon"> Wallabag

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Read-it-later service. Saves articles for offline reading, strips ads, and syncs with mobile apps.

[:octicons-book-16: Documentation](https://doc.wallabag.org/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/wallabag/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bentopdf.png" class="svc-icon"> BentoPDF

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Self-hosted PDF toolbox. Merge, split, compress, convert, rotate, and watermark PDFs without sending files to third-party services.

[:octicons-book-16: Documentation](https://github.com/Alamino/BentoPDF) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/bentopdf/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/changedetection.png" class="svc-icon"> ChangeDetection

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Monitors web pages for changes and sends notifications. Used for tracking price changes, availability alerts, and content updates.

[:octicons-book-16: Documentation](https://changedetection.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/changedetection/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/docuseal.png" class="svc-icon"> Docuseal

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Self-hosted document signing platform. Creates, distributes, and collects signatures on PDF forms.

[:octicons-book-16: Documentation](https://www.docuseal.co/docs) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/docuseal/values.yaml)

---

## Finance

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/ghostfolio.png" class="svc-icon"> Ghostfolio

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Open-source wealth management. Tracks investment portfolios across brokers and asset classes with live market data.

[:octicons-book-16: Documentation](https://ghostfol.io/en/blog/2021/07/ghostfolio-meets-self-hosting) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/ghostfolio/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/firefly-iii.png" class="svc-icon"> Firefly III

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Personal finance manager. Tracks income, expenses, and budgets with full double-entry bookkeeping.

[:octicons-book-16: Documentation](https://docs.firefly-iii.org/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/firefly/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/wordpress.png" class="svc-icon"> Wedding Site

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>homelab</code></em>

Personal wedding website. Self-hosted static site for RSVP and event information with wordpress.

[:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/wedding-site/values.yaml)

---

## Books & Reading

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/calibre-web.png" class="svc-icon"> Calibre Web

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Web interface for a Calibre e-book library. Browse, read, and download books from any browser or e-reader.

[:octicons-book-16: Documentation](https://github.com/janeczku/calibre-web) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/calibre-web/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bookstack.png" class="svc-icon"> BookLore

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Self-hosted e-book and reading library service.

[:octicons-book-16: Documentation](https://github.com/adityachandelgit/booklore) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/booklore/values.yaml)

---

## NAS & Files

Tools for storage management and filesystem operations on `hoarder`.

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" class="svc-icon"> Unraid

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Unraid</em>

Operating system and management UI for the `hoarder` NAS. Manages storage arrays, Docker containers, VMs, and user shares.

[:octicons-book-16: Documentation](https://docs.unraid.net/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/unraid/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kopia.png" class="svc-icon"> Kopia

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Backup and snapshot tool. Creates encrypted, deduplicated backups to Backblaze B2 and local repositories.

[:octicons-book-16: Documentation](https://kopia.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/kopia/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/krusader.png" class="svc-icon"> Krusader

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Dual-pane file manager used for direct filesystem operations on the NAS.

[:octicons-book-16: Documentation](https://krusader.org/) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/krusader/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/scrutiny.png" class="svc-icon"> Scrutiny

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Disk S.M.A.R.T. monitoring dashboard with historical metrics and alerts.

[:octicons-book-16: Documentation](https://github.com/AnalogJ/scrutiny) &nbsp;·&nbsp; [:octicons-file-code-16: ingress](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/homelab/external-ingress/scrutiny/values.yaml)

---

### <img src="https://cdn.simpleicons.org/git" class="svc-icon"> Ghorg

<em><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unraid.png" style="height:1em;vertical-align:middle;margin-right:4px"> hoarder · Docker</em>

Bulk Git repository cloning and synchronization tool. Mirrors GitHub organisations to the NAS.

[:octicons-book-16: Documentation](https://github.com/gabrie30/ghorg)
