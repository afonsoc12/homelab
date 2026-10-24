# Envoy Gateway

[Envoy Gateway](https://gateway.envoyproxy.io/) is the standard Kubernetes ingress
controller. It runs in `ingress` using the official `gateway-helm` chart, pinned to
v1.9.2, with one controller and one Envoy proxy replica. ingress-nginx is retained
temporarily while applications migrate to Gateway API.

## Traffic path

```text
Existing Grafana address -> ingress-nginx forwarding edge -> Envoy -> Grafana
Browser login -> Authentik -> Grafana /login/generic_oauth
```

Grafana's Helm chart creates native HTTPRoutes for HTTPS application traffic and
HTTP-to-HTTPS redirection. TLS uses the existing reflected `local-wildcard-cert`
in `ingress`. The shared Gateway accepts routes from `monitoring` only.

The original Grafana Ingress identity remains as a forwarding edge, pointing to
an ExternalName Service for `envoy.ingress.svc.cluster.local`. It performs no
forward-auth check and no longer routes directly to Grafana. Its HTTPS upstream
uses Grafana's hostname as SNI. This staging arrangement preserves the existing
DNS and MetalLB address and avoids duplicate-host admission conflicts. Envoy's
Service is ClusterIP until a later direct-entry/DNS migration. The remaining
applications continue to use ingress-nginx.

## Authentik login

Grafana uses native Generic OAuth with Authentik as its OIDC provider. Authorization
code flow uses PKCE, a confidential client secret, and refresh tokens. Anonymous
access and proxy-header authentication are disabled. Authentik's existing
`homelab-login`, `homelab-provider-authorization`, and `homelab-provider-logout`
flows are reused. No Authelia configuration is changed.

The existing `authentik_admins` group maps to Grafana organization Admin; other
users receive Viewer. This does not grant Grafana server-administrator rights.
The existing local login remains available with `?disableAutoLogin=true` for
account recovery or linking an existing local account. No insecure email-based
account linking is enabled. Verify the resulting account and role on first login.

The Authentik application and provider are registered automatically by a blueprint
mounted from the `authentik-grafana-oidc` Secret through the upstream chart.
Argo CD deploys the blueprint when this change is merged; no Terraform apply or
manual provider creation is required. The shared client secret is SOPS-encrypted
in the Authentik blueprint and Grafana values. Grafana's chart injects it through
a Kubernetes Secret rather than placing it in `grafana.ini`.

Blueprint discovery is asynchronous, so the login provider may become available
after the Kubernetes Applications have synced. Deleting the blueprint file does
not delete the Authentik application/provider it created.

## Ownership and rollout

- `envoy-gateway` owns the upstream controller and Envoy CRD charts, plus the
  GatewayClass, EnvoyProxy, and Gateway rendered with `adhoc-resources`.
  One values file supplies the controller and resource charts. The CRD chart
  enables only Envoy definitions; the cluster's existing Gateway API v1.6.3
  definitions are reused and remain outside this Application's ownership.
  The controller chart's bundled CRDs are disabled to avoid replacing them.
- `grafana` owns its native routes, forwarding edge, and OAuth client Secret.
- `authentik` owns the OIDC blueprint Secret and mounts it into its worker.

Argo CD retries initial synchronization while CRDs become available. Resources
within the Envoy Application use sync waves to create the controller before the
Gateway. A brief
first-sync routing/login interruption is possible while the controller, routes,
and Authentik blueprint converge. Nothing is applied before merge.

Controller and proxy resource requests/limits are explicit, including the proxy's
shutdown-manager container. Startup, readiness, and liveness probes use the pinned
upstream defaults. There is no persistent volume for Envoy. The deployment uses
one proxy replica; it is not a high-availability or measured memory comparison.

## Validation before merge

The pinned controller, Grafana, Authentik, and resource charts render successfully.
Helm lint, Gateway/Envoy resource schema checks, Authentik blueprint model-schema
checks, secret consistency/encryption checks, and Kubernetes server dry-runs pass.
The native Authentik blueprint validator was killed before returning a result;
blueprint application and browser login remain post-merge checks. No controller
or route was deployed during validation.

## Verification after merge

1. Confirm `envoy-gateway`, `authentik`, and `grafana` sync in Argo CD.
2. Check that `ingress/homelab` is Programmed and both Grafana HTTPRoutes are Accepted
   with resolved references. Check the Authentik blueprint status for errors.
3. Open Grafana at its existing bookmark and complete Authentik login. Verify the
   expected Grafana role, dashboards, refresh, logout, and Grafana Live/WebSockets.
4. Confirm unauthenticated requests cannot read dashboards or protected API data.
5. Check another existing application still uses its original ingress/auth path.

For rollback, revert this PR. That restores Grafana's original direct Ingress and
removes the Envoy Application while retaining shared CRDs. Authentik blueprint
objects persist and can be removed separately after rollback. The Authelia path
for all other applications is unchanged.

References: [Envoy Helm installation](https://gateway.envoyproxy.io/docs/install/install-helm/),
[Authentik Grafana integration](https://integrations.goauthentik.io/monitoring/grafana/),
[Authentik blueprints](https://docs.goauthentik.io/customize/blueprints/), and
[Grafana Generic OAuth](https://grafana.com/docs/grafana/latest/setup-grafana/configure-access/configure-authentication/generic-oauth/).
