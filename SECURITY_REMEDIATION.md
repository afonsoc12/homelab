# Security remediation status

This branch addresses the findings in `../../homelab-security-report.md` at the source level. Review the live checks below before applying changes to the cluster or OCI account.

## Fixed in this branch

- ESPHome and Music Assistant no longer request privileged execution or broad Linux capabilities. Their host networking stays in place for discovery and media features. Verify firmware build, OTA updates, player discovery, and streaming after rollout.
- Node-RED no longer uses the node network namespace. Its probes now target the pod address, and its existing service and Authentik ingress remain. Verify flows that call local or LAN services after rollout.
- Ansible now checks SSH host keys. Populate and verify the operator's `known_hosts` before running playbooks; a missing or changed host key will cause a connection failure.
- OCI no longer permits public SSH in the default security list. Confirm that SSH over the existing Tailscale management path and OCI console recovery both work before applying Terraform. Do not apply this change during a Tailscale outage.

## Open issues requiring live verification or workload-specific design

1. **Host-networked application ports may bypass Authentik.** ESPHome and Music Assistant still share a node network namespace. Test their direct UI and stream ports from guest, LAN, and VPN segments without a login. Restrict node firewall access to these ports or add native application authentication. Remove host networking only after validating discovery and playback. Host networking also remains in other automation workloads; audit those direct ports too.
2. **No explicit workload network policy.** A safe default-deny rollout requires an inventory of live pod labels, service dependencies, DNS, and the cluster network plugin's policy enforcement. Add policies namespace by namespace and test flows before enabling them. A blanket rule here could disconnect Home Assistant, MQTT, or media services.
3. **Zigbee2MQTT and WireGuard remain privileged.** Both use host devices or network interfaces. Replace privileged execution only after confirming the specific device and capability requirements on the running node. Limit node placement and device access in the meantime.
4. **Runtime access is unverified.** Confirm effective OCI security rules, host firewalls, application bind addresses, native authentication, and SSH access. Source changes alone do not prove the live systems are protected.

CI already runs a full-history Gitleaks scan. Run the dependency and deployed-state reviews separately; this branch did not alter application versions.
