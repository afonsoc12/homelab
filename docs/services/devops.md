# DevOps

Self-hosted Git forge and CI/CD automation.

---

## Git Forge & CI/CD

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/forgejo.png" class="svc-icon"> Forgejo

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>devops</code></em>

Self-hosted lightweight Git forge with built-in CI/CD (Forgejo Actions). Mirrors the public GitHub-hosted repo and backs Terraform/Ansible pipeline automation, kept isolated from untrusted GitHub PR contributors.

[:octicons-book-16: Documentation](https://forgejo.org/docs/latest/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/devops/forgejo/values.sops.yaml)

---

### <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/forgejo.png" class="svc-icon"> Forgejo Runner

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>devops</code></em>

Forgejo Actions runners (2 replicas), docker-exec mode via a bundled Docker-in-Docker sidecar. Executes CI workflows for the mirrored repo.

[:octicons-book-16: Documentation](https://forgejo.org/docs/latest/admin/actions/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/devops/forgejo-runner/values.sops.yaml)
