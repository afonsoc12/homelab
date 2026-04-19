# Monitoring

Observability stack — metrics, logs, dashboards, and alerting.

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/grafana.png" class="svc-icon"> Grafana

Dashboards and visualisation. Connects to Prometheus, Loki, and InfluxDB to provide unified monitoring views across the whole stack.

[:octicons-book-16: Documentation](https://grafana.com/docs/grafana/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/grafana/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/prometheus.png" class="svc-icon"> Prometheus Stack

Metrics collection and alerting. Deployed via `kube-prometheus-stack`, includes Prometheus, Alertmanager, kube-state-metrics, and node exporters.

[:octicons-book-16: Documentation](https://prometheus.io/docs/introduction/overview/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/prometheus-stack/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/loki.png" class="svc-icon"> Loki

Log aggregation. Collects and indexes logs from all pods and ships them to Grafana for querying with LogQL.

[:octicons-book-16: Documentation](https://grafana.com/docs/loki/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/loki/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/alloy.png" class="svc-icon"> Alloy

OpenTelemetry collector and telemetry pipeline. Scrapes metrics, tails logs, and forwards traces to the appropriate backends (Prometheus, Loki).

[:octicons-book-16: Documentation](https://grafana.com/docs/alloy/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/alloy/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/uptime-kuma.png" class="svc-icon"> Uptime Kuma

Service uptime monitoring. Checks HTTP endpoints, TCP ports, and DNS records at configurable intervals and sends alerts on downtime.

[:octicons-book-16: Documentation](https://github.com/louislam/uptime-kuma/wiki) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/uptime-kuma/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/ntfy.png" class="svc-icon"> ntfy

Self-hosted push notification server. Receives alerts from Prometheus Alertmanager, Uptime Kuma, and other services and delivers them to mobile devices.

[:octicons-book-16: Documentation](https://docs.ntfy.sh/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/monitoring/ntfy/values.sops.yaml)
