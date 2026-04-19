# Ingress

External access, authentication, and network security layer.

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authentik.png" class="svc-icon"> Authentik

Identity provider (IdP). Handles SSO, OAuth2/OIDC, SAML, and LDAP for all protected services. The primary auth system going forward.

[:octicons-book-16: Documentation](https://docs.goauthentik.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/authentik/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authelia.png" class="svc-icon"> Authelia

SSO and 2FA authentication proxy. Currently being decommissioned in favour of Authentik.

[:octicons-book-16: Documentation](https://www.authelia.com/configuration/prologue/introduction/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/authelia/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lldap.png" class="svc-icon"> LLDAP

Lightweight LDAP server. Provides a simple user directory consumed by Authentik and other LDAP-aware services.

[:octicons-book-16: Documentation](https://github.com/lldap/lldap) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/lldap/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/nginx.png" class="svc-icon"> ingress-nginx

Kubernetes ingress controller. Routes external HTTP/HTTPS traffic to the appropriate services based on hostname and path rules.

[:octicons-book-16: Documentation](https://kubernetes.github.io/ingress-nginx/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/ingress-nginx/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/cloudflare.png" class="svc-icon"> Cloudflared

Cloudflare Tunnel daemon. Establishes an outbound-only connection from the cluster to the Cloudflare edge, exposing services publicly without opening inbound firewall ports.

[:octicons-book-16: Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/cloudflared/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/wireguard.png" class="svc-icon"> Wireguard

VPN server. Provides direct, encrypted network-level access to the cluster for trusted devices.

[:octicons-book-16: Documentation](https://www.wireguard.com/quickstart/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/ingress/wireguard/values.yaml)
