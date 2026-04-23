# Databases

Shared stateful services used by apps across multiple namespaces.

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/postgresql.png" class="svc-icon"> PostgreSQL

Primary relational database. Shared across multiple apps in the cluster (Authentik, Ghostfolio, Firefly, etc.).

[:octicons-book-16: Documentation](https://www.postgresql.org/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/databases/postgres/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/mariadb.png" class="svc-icon"> MariaDB

MySQL-compatible relational database. Used by apps that require MySQL-specific features or were migrated from MySQL.

[:octicons-book-16: Documentation](https://mariadb.org/documentation/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/databases/mariadb/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/redis.png" class="svc-icon"> Redis

In-memory key-value store. Used as a cache and session store by multiple apps.

[:octicons-book-16: Documentation](https://redis.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/databases/redis/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/influxdb.png" class="svc-icon"> InfluxDB

Time-series database. Stores sensor readings, energy metrics, and other time-stamped data from Home Assistant and IoT devices.

[:octicons-book-16: Documentation](https://docs.influxdata.com/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/databases/influxdb/values.sops.yaml)
