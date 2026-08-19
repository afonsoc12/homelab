---
name: unraid-docker
description: Deploy or migrate an app to run as a native-looking Docker container on Unraid (host "hoarder") via Ansible + Docker Compose, with a matching DockerMan GUI template. Trigger when the user wants to add/move an app to Unraid, make an unmanaged container editable in the Unraid GUI, or asks about docker/hoarder/, the docker_compose Ansible role, or DockerMan templates.
---

# Unraid Docker Deployment

Apps run on Unraid as plain Docker Compose stacks, deployed by Ansible's
`docker_compose` role (`ansible/playbooks/unraid.yml`). A second step in the
same role renders a DockerMan XML template per service so the container also
shows up as a normal, **editable** app in the Unraid GUI — without that step
it's a real container but Unraid treats it as "unmanaged" (no edit button).

Compose is the single source of truth. `unraid.yml` is optional and only
fills in GUI-only fields the compose spec has no place for (icon, WebUI URL,
category, per-field descriptions).

## File layout

```
docker/hoarder/<stack>/
  docker-compose.yaml   # required
  unraid.yml            # optional — DockerMan metadata, keyed by service name
  secrets.sops.yaml      # optional — sops-encrypted key: value pairs -> .env
```

`hoarder` here is the inventory hostname — the `docker_compose` role finds
stacks at `docker/<inventory_hostname>/`, same convention as the `docker`
group (e.g. `docker/rpi-4b/adguard/`). A second Unraid box would get its own
`docker/<hostname>/` folder, not share this one.

## Adding or migrating an app

1. **Check what port is actually free.** Unraid's own management nginx binds
   `:8080` on every interface — it will NOT show up in `docker ps`, only in
   `ss -tlnp`. Always check the host directly before picking a port:
   ```bash
   ssh root@<host> "ss -tlnp | grep -oE ':[0-9]+' | sort -u -t: -k2 -n"
   ```

2. **Write `docker-compose.yaml`.** Match Unraid's own conventions:
   - `PUID=99`, `PGID=100` (Unraid's native `nobody:users`), not an
     app-specific UID, unless the app's data already has different ownership
     you need to preserve.
   - Volumes flat under `/mnt/user/appdata/<stack>` where the upstream image
     supports it (check the app's own official Unraid CA template if it has
     one — GitHub repo, folder often named `unraid-ca/` or similar. Pulling
     real values from there beats guessing).
   - Anything that shouldn't be committed in plaintext (not just credentials —
     e.g. your own domain name in a hostname, **or a raw LAN IP** — this repo
     treats IPs as secrets everywhere, same rule as `docs/`) goes in
     `secrets.sops.yaml` as a plain `KEY: value` pair, referenced in compose
     as `${KEY}`. The role decrypts it to a `.env` file (mode `0600`) on the
     host next to the compose file; `docker compose` picks it up
     automatically. Nothing about this mechanism is compose-specific to
     Unraid — same pattern the `docker` group stacks use.

3. **Write `unraid.yml`** (optional, but do it — a bare compose file renders
   a bare, ugly template). Schema:
   ```yaml
   <service-name>:
     icon: <url>              # prefer https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/<name>.png
                               # or https://cdn.jsdelivr.net/gh/selfhst/icons/png/<name>.png (same convention
                               # docs/ uses). Falls back to the app's own hosted icon if neither has it.
     webui: "http://[IP]:[PORT:8080]/"   # literal placeholder syntax, Unraid resolves it
     category: "MediaApp:Video"          # see Unraid CA category list
     overview: "..."
     registry: <url>           # optional -> <Registry>, see below
     project_url: <url>       # optional -> <Project>
     support_url: <url>       # optional -> <Support>
     license: MIT              # optional -> <License>
     port_names: {}            # {container_port: display name}
     port_descriptions: {}
     volume_names: {}          # {container_path: display name}
     volume_descriptions: {}
     env_names: {}             # {ENV_KEY: display name}
     env_descriptions: {}      # {ENV_KEY: description shown under the field}
     env_display: {}           # {ENV_KEY: 'always'|'advanced'}, default always
     env_defaults: {}          # {ENV_KEY: override}, default is the compose value itself
     secret_env: []            # env keys to mask + blank out in the XML
   ```
   Non-secret env vars render with their **real current value** from compose
   as both `Default` and the tag's inner text — the GUI shows actual running
   config, not blanks. `secret_env` vars are always rendered empty/masked,
   regardless of what's in compose, even though the container itself gets
   the real value via `.env`.

   `<Registry>` (Unraid's "check for updates" link) auto-derives from the
   image name if `registry:` isn't set — `ghcr.io/<owner>/<repo>` becomes
   the GitHub packages page, `docker.io` images become the Hub page (official
   single-segment images use `/_/<name>`, user images use `/r/<user>/<name>/`).
   Verify the rendered XML matches what the app's own registry page actually
   is — auto-derivation is a guess, not authoritative.

   **ghcr.io org vs personal-account owners use different URL shapes** and
   this can't be told apart from the image name alone:
   - Personal account: `https://github.com/<owner>/<repo>/pkgs/container/<repo>`
     (what auto-derivation assumes)
   - Organization (e.g. `linuxserver/*`): `https://github.com/orgs/<org>/packages/container/package/<repo>`

   Check which one applies before trusting the auto-derived value:
   ```bash
   gh api users/<owner> --jq '.type'   # "User" or "Organization"
   ```
   If it's an Organization, set `registry:` explicitly in `unraid.yml` — the
   auto-derived link will 404.

4. **If migrating an app with existing data** (e.g. from a k8s PVC): copy the
   data out to a temp location, `rsync` it to
   `/mnt/user/appdata/<stack>/...` on the Unraid host, `chown -R 99:100` it,
   *then* deploy — don't let the first deploy create empty dirs first and
   fight ownership after.

5. **Deploy:**
   ```bash
   cd ansible
   uv run ansible-playbook playbooks/unraid.yml
   ```

6. **If this is a fresh Unraid box with no Python** (`ansible_python_interpreter`
   fails with "not found"), bootstrap it first — Unraid ships no Python by
   default:
   ```bash
   ssh root@<host> "yes | un-get install python3"
   ```
   `un-get` prompts for confirmation even in one-shot mode — pipe `yes` into
   it. The `docker_prune` task also needs `python-requests` on the target:
   ```bash
   ssh root@<host> "yes | un-get install python-requests python-urllib3 python-idna python-certifi python-charset-normalizer"
   ```

7. **If the container isn't editable, or the WebUI/icon don't show in the
   container list**, check labels — this is two *separate* mechanisms that
   are easy to conflate:
   - The `<WebUI>`/`<Icon>` fields in the DockerMan **XML** only affect the
     Edit form.
   - The clickable WebUI link and icon in the main container **list** are
     read from the running container's own **labels**
     (`net.unraid.docker.webui`, `net.unraid.docker.icon`), not the XML.
   ```bash
   docker inspect <name> --format '{{json .Config.Labels}}' | python3 -m json.tool | grep unraid
   ```
   Should show `net.unraid.docker.managed=dockerman` plus `webui`/`icon` if
   set in `unraid.yml`. The role injects all three into every service on
   `unraid`-group hosts automatically (`unraid-labels.yaml.j2`, overwrites
   the synced compose file before deploy, reading `webui`/`icon` straight
   out of that stack's `unraid.yml`) — if any are missing, the container was
   deployed some other way (manual `docker compose up`, Unraid's own "Add
   Container" GUI flow, etc.) and needs a `docker compose up --force-recreate`
   through Ansible to pick them up. **Labels are immutable** — `docker update`
   cannot add them after the fact, the container must be recreated.

8. **Register cluster-side ingress** if this app needs a hostname reachable
   from inside the cluster (Authelia, TLS, etc.) — see the `k8s-app` skill's
   "External service" section. Same pattern as `radarr`/`sonarr`/etc.:
   `kubernetes/apps/homelab/external-ingress/<app>/values.yaml` pointing at
   `{{ .Values.ips_tailscale.hoarder }}:<port>`, registered in the
   `external-ingress` ApplicationSet.

## Verifying

```bash
docker ps --filter name=<stack> --format '{{.Status}}\t{{.Ports}}'
curl -s -o /dev/null -w '%{http_code}\n' http://<host>:<port>/<health-path>
cat /boot/config/plugins/dockerMan/templates-user/<stack>.xml   # sanity-check rendered fields
```
