---
paths:
  - "kubernetes/**"
---
# ArgoCD Conventions

- Never use `latest` image tags — always pin version to exact chart, docker image or package version
- IP keys in `values.sops.yaml` use dashes (`rpi-4b`, `k3s-m1`)
- Labels in external-ingress values use dashes (`host: rpi-4b`)
- Dashed IP keys require `index` syntax: `{{ index .Values.ips "rpi-z2w" }}`
