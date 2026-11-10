---
paths:
  - "ansible/**"
---
# Ansible Rules

- Always run from `ansible/` directory via `uv run ansible-playbook ...`
- Playbooks, roles and tasks use `.yml` extension (Ansible convention)
- `maintenance` role runs on every play with no tags — changes affect all servers
- Files in `@ansible/inventory` might be sops encrypted — use `{{ ansible_user }}` in templates, never hardcode whats a secret
