# Observability

Metrics, logs, dashboards, alerting, and uptime monitoring.

All services run on the **k3s cluster** (`monitoring` namespace).

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/grafana.png" class="svc-icon"> Grafana

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Dashboards and visualisation. Connects to Prometheus, Loki, and InfluxDB to provide unified monitoring views across the whole stack.

[:octicons-book-16: Documentation](https://grafana.com/docs/grafana/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/grafana/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/prometheus.png" class="svc-icon"> Prometheus Stack

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Metrics collection and alerting. Deployed via `kube-prometheus-stack`, includes Prometheus, Alertmanager, kube-state-metrics, and node exporters.

[:octicons-book-16: Documentation](https://prometheus.io/docs/introduction/overview/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/prometheus-stack/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/loki.png" class="svc-icon"> Loki

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Log aggregation. Collects and indexes logs from all pods and ships them to Grafana for querying with LogQL.

[:octicons-book-16: Documentation](https://grafana.com/docs/loki/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/loki/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/alloy.png" class="svc-icon"> Alloy

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

OpenTelemetry collector and telemetry pipeline. Scrapes metrics, tails logs, and forwards traces to the appropriate backends (Prometheus, Loki).

[:octicons-book-16: Documentation](https://grafana.com/docs/alloy/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/alloy/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/uptime-kuma.png" class="svc-icon"> Uptime Kuma

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Service uptime monitoring. Checks HTTP endpoints, TCP ports, and DNS records at configurable intervals and sends alerts on downtime.

[:octicons-book-16: Documentation](https://github.com/louislam/uptime-kuma/wiki) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/uptime-kuma/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/ntfy.png" class="svc-icon"> ntfy

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Self-hosted push notification server. Receives alerts from Prometheus Alertmanager, Uptime Kuma, and PagerDuty and delivers them to mobile devices.

[:octicons-book-16: Documentation](https://docs.ntfy.sh/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/ntfy/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/telegraf.png" class="svc-icon"> Speedtest Exporter

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Telegraf instance with an `exec` input that runs periodic internet speed tests and exposes results as Prometheus metrics for Grafana dashboards.

[:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/speedtest-exporter/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unpoller.png" class="svc-icon"> Unpoller

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Exports UniFi controller metrics (clients, traffic, device health) to Prometheus for visualisation in Grafana.

[:octicons-book-16: Documentation](https://unpoller.com/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/unpoller/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/healthchecks.png" class="svc-icon"> Cluster Heartbeat

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Custom heartbeat job that sends a periodic ping to [healthchecks.io](https://healthchecks.io). If the ping stops, healthchecks.io fires a PagerDuty alert — confirming the cluster is alive end-to-end.

---

## <img src="https://cdn.simpleicons.org/octopusdeploy" class="svc-icon"> OctoTrack

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>monitoring</code></em>

Octopus Energy electricity usage dashboard. Pulls consumption data from the Octopus Energy API and displays it in Grafana.

[:octicons-book-16: Source](https://github.com/afonsoc12/octo-track) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/octotrack/values.yaml)
