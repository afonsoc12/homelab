# Migrating a Service to Contour and SSO

Use this checklist to migrate an existing service to standard Kubernetes Ingress with [Contour](https://projectcontour.io/), which configures [Envoy](https://www.envoyproxy.io/). Add Authentik for sign-in and Cloudflare Access when the public endpoint needs an additional access gate. Gateway API resources are not required.

Examples contain placeholders, not live deployment settings. Keep private hostnames, addresses, credentials, and account details in SOPS-encrypted configuration.

For a new service, first follow [Adding a New App](adding-app.md), then use this checklist for its routing and authentication.

## 1. Check the Application's Authentication Options

Read the application's official documentation for the deployed edition and version. Check licensing, callback requirements, supported grants, account linking, logout, API clients, and background integrations before changing configuration.

| Application support | Approach |
| --- | --- |
| Native OpenID Connect | Connect the application directly to Authentik. Keep its normal Service as the Ingress destination. |
| A documented OAuth login integration | Follow the vendor's supported integration and identity-validation requirements. |
| No supported SSO integration | Use an Authentik proxy where an outer login gate is needed. Retain the application's own login unless a separate, secure account-linking design has been verified. |

OIDC adds user authentication to OAuth 2.0; OAuth 2.0 alone is an authorization framework. A Cloudflare Access login does not automatically create a login session inside the application. See [Authentik's OAuth/OIDC overview](https://docs.goauthentik.io/add-secure-apps/providers/oauth2/).

## 2. Preserve Existing Accounts

Determine how the application associates an external identity with an existing account. Use its documented linking or migration mechanism and verify that existing data and permissions stay with the intended account.

Do not assume matching usernames will link accounts. Do not enable automatic linking based on unverified email addresses. Check whether automatic account creation could produce duplicates before testing with an existing user.

## 3. Configure Native OIDC When Available

Create an Authentik application/provider pair and configure the application's supported OIDC settings:

- Use authorization code with PKCE (`S256`). Use client authentication for confidential server-side clients; never place a client secret in browser code.
- Register exact HTTPS callback URLs. Configure only required scopes and grants.
- Use a signing key and OIDC discovery/JWKS verification. Validate the expected issuer, audience, and request state; use nonce validation where required by the integration.
- Restrict application access explicitly. Configure the application's permission mapping separately from the ability to sign in.
- Store credentials in SOPS, then test account linking and logout before changing local-login settings.

Follow the application's integration guide, [Authentik's provider documentation](https://docs.goauthentik.io/add-secure-apps/providers/oauth2/), and [OAuth security best practice](https://www.rfc-editor.org/rfc/rfc9700.html). Avoid implicit and password grants for browser login.

## 4. Change the Existing Ingress to Contour

Use the application's existing Helm Ingress settings and keep the Ingress in the application's namespace. Chart schemas vary: inspect a rendered manifest rather than copying values between charts.

For the repository's `homelab-svc` chart, native application authentication normally uses the default chart-created Service:

```yaml
ingress:
  enabled: true
  className: contour
  authelia: false
  authentik: false
  annotations:
    ingress.kubernetes.io/force-ssl-redirect: "true"
  tls:
    - secretName: REPLACE_WITH_EXISTING_CERTIFICATE_SECRET
  hosts:
    - host: app.{{ .Values.domain }}
      paths:
        - path: /
          pathType: Prefix
```

Here, `authelia` and `authentik` control nginx forward-auth annotations; they do not control the application's native SSO. Contour does not implement nginx's `auth-url` and `auth-signin` annotations.

Check that the generated Ingress has the correct class, backend, and TLS hostname. `homelab-svc` can infer TLS hostnames for Contour; upstream charts may require an explicit `tls[].hosts` list. Preserve the certificate and hostname when possible.

Translate annotations by behavior, not by spelling. Configure WebSockets only for routes that need them and use bounded timeouts appropriate to the application. Remove nginx-specific annotations. Consult [Contour's annotation reference](https://projectcontour.io/docs/main/config/annotations/).

### Applications That Need a Proxy Gate

An Authentik proxy provider associates the browser-facing hostname with an upstream application. The Ingress routes to the proxy; after authorization, the proxy forwards the request to the application's existing Service. The application Service is still needed.

In `homelab-svc`, select the proxy through the existing host/path structure:

```yaml
# Inside ingress.hosts[].paths[]; use only for proxy-protected routes.
- path: /
  pathType: Prefix
  service:
    name: REPLACE_WITH_NAMESPACE_LOCAL_PROXY_SERVICE
    port: 9000
```

Standard Ingress backends reference Services in the same namespace. An embedded outpost can be suitable when routing permits; a dedicated outpost is a placement choice, not a requirement for every service or namespace. Reuse a suitable outpost where practical. Keep one owner for each Ingress and avoid duplicate proxy-generated routes when the app chart already defines them.

A proxy gate does not protect direct access to an application backend. Retain native authentication or verify effective origin isolation before trusting identity headers. Cloudflare headers alone are not proof of identity on a bypassable backend. See [Authentik proxy providers](https://docs.goauthentik.io/add-secure-apps/providers/proxy/).

## 5. Add Cloudflare Access for Public Access

If needed, configure Authentik as a Cloudflare OIDC identity provider using the [official integration guide](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/authentik-oidc/). Register the callback for the appropriate Access team and keep its client credentials encrypted.

Create an Access application for the intended public hostname and define an explicit allow policy. Restrict it to the intended identity provider; provider-selection bypass is optional when only one provider is available. Choose a bounded session duration.

For a Tunnel origin, enable Access JWT validation with the application's audience and the correct team name. Use HTTPS to the origin with certificate verification enabled and the hostname matching the certificate. See [Cloudflare Tunnel origin parameters](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/origin-parameters/).

The identity provider's authorization, token, and signing-key endpoints must remain reachable. Do not create an Access login dependency that recursively protects its own identity provider. Check firewall/challenge behavior against the supported integration.

Decide how LAN DNS should behave: local routing needs its own authentication protection, while public routing passes through Access. Plan API clients and webhooks explicitly; an interactive Access gate can block unattended clients.

## 6. Review GitOps and Terraform Together

Keep application routing in its existing chart values. Manage identity-provider, Access, tunnel, and DNS resources in their corresponding Terraform modules. Inspect the rendered Ingress and saved Terraform plans before requesting a merge.

Check every planned change, including shared tunnel configuration. Preserve unrelated routes and investigate unrelated drift separately. Keep saved plans and decrypted manifests out of commits and public logs.

Coordinate GitOps and Terraform so the destination route and its dependencies are ready when DNS or tunnel routing changes. A merged PR does not itself apply Terraform. Apply only changes authorized for the migration; never merge the PR automatically.

## 7. Verify Both Access Paths

| Check | Expected result |
| --- | --- |
| LAN DNS and HTTPS | Intended destination and a valid certificate. |
| Public DNS and HTTPS | Intended public route, with Access enforced when configured. |
| Anonymous browser | Required login gate is enforced. |
| Authorized browser | Complete sign-in reaches the application with the intended existing account and permissions. |
| Unauthorized identity | Access is denied. |
| Application features | Uploads, WebSockets, API clients, and background integrations work as intended. |
| Logout and another private browser session | Session behavior matches the supported integration. |

A redirect to a login page is only a routing check. Complete an authenticated browser login before declaring SSO working. Correlate application, identity-provider, proxy, and edge logs without publishing credentials or personal details.

If login fails, identify the failing request and layer before changing settings. Do not disable TLS verification, widen access policies, or remove firewall restrictions to mask an unexplained error.
