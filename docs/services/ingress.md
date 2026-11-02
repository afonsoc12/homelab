# Networking & Access

Traffic routing, VPN, DNS filtering, identity, and authentication.

---

## Identity & Authentication

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authentik.png" class="svc-icon"> Authentik

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Identity provider for single sign-on and required multi-factor authentication. New users join through administrator-issued [invitations](https://docs.goauthentik.io/users-sources/user/invitations/). Supports native application integrations and [proxy protection](https://docs.goauthentik.io/add-secure-apps/providers/proxy/) for applications without built-in login.

[:octicons-book-16: Documentation](https://docs.goauthentik.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/authentik/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authelia.png" class="svc-icon"> Authelia

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

SSO and 2FA authentication proxy. Still protects services awaiting migration. Keep it running until those consumers and all ingress templates support Authentik.

[:octicons-book-16: Documentation](https://www.authelia.com/configuration/prologue/introduction/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/authelia/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lldap.png" class="svc-icon"> LLDAP

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Lightweight LDAP server used by the legacy authentication stack. Keep it running until its consumers migrate; Authentik currently uses its built-in source.

[:octicons-book-16: Documentation](https://github.com/lldap/lldap) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/lldap/values.sops.yaml)

---

## Ingress & Tunnels

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/contour.png" class="svc-icon"> [Contour](https://projectcontour.io/)

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Standard Kubernetes ingress controller, using [Envoy](https://www.envoyproxy.io/) for HTTP/HTTPS routing and TLS termination.

[:octicons-book-16: Documentation](../kubernetes/contour.md) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/contour/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/nginx.png" class="svc-icon"> ingress-nginx

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Temporary ingress controller retained while applications migrate to [Contour](https://projectcontour.io/).

[:octicons-book-16: Documentation](https://kubernetes.github.io/ingress-nginx/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/ingress-nginx/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/cloudflare.png" class="svc-icon"> Cloudflared

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Cloudflare Tunnel daemon. Establishes an outbound-only connection from the cluster to the Cloudflare edge, exposing services publicly without opening inbound firewall ports.

[:octicons-book-16: Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/cloudflared/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/wireguard.png" class="svc-icon"> Wireguard

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

VPN server. Provides direct, encrypted network-level access to the cluster for trusted devices.

[:octicons-book-16: Documentation](https://www.wireguard.com/quickstart/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/wireguard/values.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/cloudflare.png" class="svc-icon"> Cloudflare DDNS

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>ingress</code></em>

Dynamic DNS updater for Cloudflare. Two instances run in parallel — one for the PT zone, one for the UK zone — keeping DNS records in sync with the current public IP.

[:octicons-file-code-16: values-pt.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/cloudflare-ddns-pt/values.yaml) &nbsp;·&nbsp; [:octicons-file-code-16: values-uk.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/cloudflare-ddns-uk/values.yaml)

---

## DNS Filtering

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/adguard-home.png" class="svc-icon"> AdGuard Home

*rpi-4b · Docker**

Network-wide DNS ad blocker. Acts as the local DNS resolver for the LAN, blocking ads and trackers at the DNS level for all devices.

[:octicons-book-16: Documentation](https://adguard.com/en/adguard-home/overview.html)

---

## Network Hardware

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/unifi.png" class="svc-icon"> UniFi Controller

*UniFi Cloud Gateway Ultra**

Network management controller for UniFi access points, switches, and the Cloud Gateway Ultra itself. Handles VLAN configuration, client monitoring, and firmware updates.

[:octicons-book-16: Documentation](https://help.ui.com/hc/en-us/categories/200320654)
