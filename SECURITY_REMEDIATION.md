# Security remediation status

This branch addresses the findings in `../../homelab-security-report.md` at the source level. Review the live checks below before applying changes to the cluster or OCI account.

## Fixed in this branch

- ESPHome and Music Assistant no longer request privileged execution or broad Linux capabilities. Their host networking stays in place for discovery and media features. Verify firmware build, OTA updates, player discovery, and streaming after rollout.
- Node-RED no longer uses the node network namespace. Its probes now target the pod address, and its existing service and Authentik ingress remain. Verify flows that call local or LAN services after rollout.
- Ansible now checks SSH host keys. Populate and verify the operator's `known_hosts` before running playbooks; a missing or changed host key will cause a connection failure.
- OCI no longer permits public SSH in the default security list. Confirm that SSH over the existing Tailscale management path and OCI console recovery both work before applying Terraform. Do not apply this change during a Tailscale outage.

## Open issues requiring live verification or workload-specific design

1. **Confirm no internet path to host-networked ports.** ESPHome and Music Assistant are pinned to the home node `k3s-m1`. The repository documents Cloudflare Tunnel and VPN as external paths; its tunnel routes to Contour, and the Music Assistant stream ingress forwards to the Authentik proxy. A direct LAN connection is acceptable for this deployment. Verify that the router has no port forwards to their direct ports and that no public DNS or tunnel route targets the node ports. Cloudflare Access is not configured for the Music Assistant stream tunnel route, so its public protection depends on the Authentik ingress. Check the effective Cloudflare Access and ingress configuration in the live environment. Retain host networking for discovery and playback.
2. **No explicit workload network policy.** A safe default-deny rollout requires an inventory of live pod labels, service dependencies, DNS, and the cluster network plugin's policy enforcement. Add policies namespace by namespace and test flows before enabling them. A blanket rule here could disconnect Home Assistant, MQTT, or media services.
3. **Zigbee2MQTT and WireGuard remain privileged.** Both use host devices or network interfaces. Replace privileged execution only after confirming the specific device and capability requirements on the running node. Limit node placement and device access in the meantime.
4. **Runtime access is unverified.** Confirm effective OCI security rules, host firewalls, application bind addresses, native authentication, and SSH access. Source changes alone do not prove the live systems are protected.

CI already runs a full-history Gitleaks scan. Run the dependency and deployed-state reviews separately; this branch did not alter application versions.

## External access enforcement in this branch

The Cloudflare tunnel now requires an Access JWT for every configured public route. The Music Assistant stream and Alexa skill routes use the owner-only interactive Access policy. The Authentik hostname uses a dedicated Cloudflare one-time PIN identity provider, restricted to the owner email. Terraform provisions the PIN provider and the application explicitly permits only that provider, avoiding an Authentik login loop. The public Home Assistant OAuth token bypass is removed; its requests now fall through to the protected Home Assistant route.

**Functional impact:** Alexa account linking, token refresh, Music Assistant skill calls, and remote media playback will fail unless those clients can authenticate to Cloudflare Access. The current integration does not show service-token headers for those clients. Do not deploy this branch expecting Alexa to keep working. A supported client-side Access authentication mechanism is needed before those features can be restored under the required policy. Confirm the new one-time PIN reaches the owner mailbox before protecting Authentik in production. Test Authentik login and OAuth redirects after deployment.

The live Kubernetes API confirmed that the Music Assistant public ingresses forward to the Authentik automation proxy. Live Cloudflare account state and router port forwards were not inspected; compare the Terraform plan against the account before apply.
