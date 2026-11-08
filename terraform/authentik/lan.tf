locals {
  lan_proxy_apps = {
    "home-assistant" = {
      name      = "Home Assistant"
      namespace = "automation"
      host      = "home"
      upstream  = "http://home-assistant.automation.svc.cluster.local:8123"
      # Home Assistant enforces native authentication on API and login endpoints.
      skip_path_regex = "^/(api|auth)(/|$)"
    }
    "calibre-web" = {
      name      = "Calibre-Web"
      namespace = "homelab"
      host      = "calibre"
      upstream  = "http://calibre-web-external-external-svc.homelab.svc.cluster.local:8083"
    }
    "freshrss" = {
      name      = "FreshRSS"
      namespace = "homelab"
      host      = "rss"
      upstream  = "http://freshrss.homelab.svc.cluster.local:80"
    }
    "adguard" = {
      name      = "adguard"
      namespace = "homelab"
      host      = "adguard.local"
      upstream  = "http://adguard-external-external-svc.homelab.svc.cluster.local:80"
    }
    "airflow" = {
      name      = "airflow"
      namespace = "addons"
      host      = "airflow.local"
      upstream  = "http://airflow.addons.svc.cluster.local:8080"
    }
    "alertmanager" = {
      name      = "alertmanager"
      namespace = "monitoring"
      host      = "alertmanager.local"
      upstream  = "http://promstack-alertmanager.monitoring.svc.cluster.local:9093"
    }
    "bambuddy" = {
      name      = "bambuddy"
      namespace = "homelab"
      host      = "bambu.local"
      upstream  = "http://bambuddy.homelab.svc.cluster.local:8000"
    }
    "bazarr" = {
      name      = "bazarr"
      namespace = "homelab"
      host      = "bazarr.local"
      upstream  = "http://bazarr-external-external-svc.homelab.svc.cluster.local:6767"
    }
    "bentopdf" = {
      name      = "bentopdf"
      namespace = "homelab"
      host      = "pdf.local"
      upstream  = "http://bentopdf.homelab.svc.cluster.local:8080"
    }
    "booklore" = {
      name      = "booklore"
      namespace = "homelab"
      host      = "booklore.local"
      upstream  = "http://booklore-external-external-svc.homelab.svc.cluster.local:6060"
    }
    "changedetection" = {
      name      = "changedetection"
      namespace = "homelab"
      host      = "changedetection.local"
      upstream  = "http://changedetection.homelab.svc.cluster.local:5000"
    }
    "cookistash" = {
      name      = "cookistash"
      namespace = "homelab"
      host      = "cookistash.local"
      upstream  = "http://cookistash.homelab.svc.cluster.local:8000"
    }
    "decide" = {
      name      = "decide"
      namespace = "homelab"
      host      = "decide.local"
      upstream  = "http://decide-external-external-svc.homelab.svc.cluster.local:8090"
    }
    "docuseal" = {
      name      = "docuseal"
      namespace = "homelab"
      host      = "sign.local"
      upstream  = "http://docuseal.homelab.svc.cluster.local:3000"
    }
    "glance" = {
      name      = "glance"
      namespace = "homelab"
      host      = "local"
      upstream  = "http://glance.homelab.svc.cluster.local:8080"
    }
    "grocy" = {
      name      = "grocy"
      namespace = "automation"
      host      = "grocy.local"
      upstream  = "http://grocy.automation.svc.cluster.local:80"
    }
    "hyperion" = {
      name      = "hyperion"
      namespace = "homelab"
      host      = "hyperion.local"
      upstream  = "http://hyperion-external-external-svc.homelab.svc.cluster.local:8090"
    }
    "krusader" = {
      name      = "krusader"
      namespace = "homelab"
      host      = "krusader.local"
      upstream  = "http://krusader-external-external-svc.homelab.svc.cluster.local:8088"
    }
    "lidarr" = {
      name      = "lidarr"
      namespace = "homelab"
      host      = "lidarr.local"
      upstream  = "http://lidarr-external-external-svc.homelab.svc.cluster.local:8686"
    }
    "lldap" = {
      name      = "lldap"
      namespace = "ingress"
      host      = "ldap.local"
      upstream  = "http://lldap.ingress.svc.cluster.local:17170"
    }
    "longhorn" = {
      name      = "Longhorn"
      namespace = "longhorn-system"
      host      = "longhorn.local"
      upstream  = "http://longhorn-frontend.longhorn-system.svc.cluster.local:80"
    }
    "music-assistant" = {
      name      = "music-assistant"
      namespace = "automation"
      host      = "music-assistant.local"
      upstream  = "http://music-assistant.automation.svc.cluster.local:8095"
    }
    "music-assistant-alexa-skill" = {
      name      = "Music Assistant Alexa Skill"
      namespace = "automation"
      host      = "music-assistant-alexa-skill"
      upstream  = "http://music-assistant-alexa-skill.automation.svc.cluster.local:5000"
    }
    "music-assistant-stream" = {
      name      = "Music Assistant Stream"
      namespace = "automation"
      host      = "music-assistant-stream"
      upstream  = "http://music-assistant.automation.svc.cluster.local:8097"
    }
    "n8n" = {
      name      = "n8n"
      namespace = "automation"
      host      = "n8n.local"
      upstream  = "http://n8n.automation.svc.cluster.local:5678"
    }
    "navidrome" = {
      name      = "navidrome"
      namespace = "homelab"
      host      = "navidrome.local"
      upstream  = "http://navidrome-external-external-svc.homelab.svc.cluster.local:4533"
    }
    "node-red" = {
      name      = "node-red"
      namespace = "automation"
      host      = "node-red.local"
      upstream  = "http://node-red.automation.svc.cluster.local:1880"
    }
    "ntfy" = {
      name      = "ntfy"
      namespace = "monitoring"
      host      = "ntfy.local"
      upstream  = "http://ntfy.monitoring.svc.cluster.local:80"
    }
    "octo-track" = {
      name      = "octo-track"
      namespace = "monitoring"
      host      = "electricity.local"
      upstream  = "http://octo-track.monitoring.svc.cluster.local:8501"
    }
    "paperless" = {
      name      = "paperless"
      namespace = "homelab"
      host      = "paperless.local"
      upstream  = "http://paperless.homelab.svc.cluster.local:8000"
    }
    "prometheus" = {
      name      = "prometheus"
      namespace = "monitoring"
      host      = "prometheus.local"
      upstream  = "http://promstack-prometheus.monitoring.svc.cluster.local:9090"
    }
    "prowlarr" = {
      name      = "prowlarr"
      namespace = "homelab"
      host      = "prowlarr.local"
      upstream  = "http://prowlarr-external-external-svc.homelab.svc.cluster.local:9696"
    }
    "qbittorrent" = {
      name      = "qbittorrent"
      namespace = "homelab"
      host      = "qbit.local"
      upstream  = "http://qbittorrent-external-external-svc.homelab.svc.cluster.local:6880"
    }
    "radarr" = {
      name      = "radarr"
      namespace = "homelab"
      host      = "radarr.local"
      upstream  = "http://radarr-external-external-svc.homelab.svc.cluster.local:7878"
    }
    "radarr-4k" = {
      name      = "radarr-4k"
      namespace = "homelab"
      host      = "radarr-4k.local"
      upstream  = "http://radarr-4k-external-external-svc.homelab.svc.cluster.local:7879"
    }
    "scrutiny" = {
      name      = "scrutiny"
      namespace = "homelab"
      host      = "scrutiny.local"
      upstream  = "http://scrutiny-external-external-svc.homelab.svc.cluster.local:8084"
    }
    "seerr" = {
      name      = "Seerr"
      namespace = "homelab"
      host      = "seerr"
      upstream  = "http://seerr-external-external-svc.homelab.svc.cluster.local:5055"
    }
    "sonarr" = {
      name      = "sonarr"
      namespace = "homelab"
      host      = "sonarr.local"
      upstream  = "http://sonarr-external-external-svc.homelab.svc.cluster.local:8989"
    }
    "spliit" = {
      name      = "Spliit"
      namespace = "homelab"
      host      = "split"
      upstream  = "http://spliit.homelab.svc.cluster.local:3000"
    }
    "tautulli" = {
      name      = "tautulli"
      namespace = "homelab"
      host      = "tautulli.local"
      upstream  = "http://tautulli-external-external-svc.homelab.svc.cluster.local:8181"
    }
    "tdarr" = {
      name      = "tdarr"
      namespace = "homelab"
      host      = "tdarr.local"
      upstream  = "http://tdarr-external-external-svc.homelab.svc.cluster.local:8265"
    }
    "tracktor" = {
      name      = "tracktor"
      namespace = "homelab"
      host      = "tracktor.local"
      upstream  = "http://tracktor.homelab.svc.cluster.local:3000"
    }
    "wealthfolio" = {
      name      = "wealthfolio"
      namespace = "homelab"
      host      = "wealth.local"
      upstream  = "http://wealthfolio.homelab.svc.cluster.local:8088"
    }
    "wedding-site" = {
      name      = "wedding-site"
      namespace = "homelab"
      host      = "mariana-afonso.local"
      upstream  = "http://wedding-site.homelab.svc.cluster.local:80"
    }
    "wireguard" = {
      name      = "wireguard"
      namespace = "ingress"
      host      = "wg.local"
      upstream  = "http://wireguard.ingress.svc.cluster.local:51821"
    }
    "wled-kitchen" = {
      name      = "wled-kitchen"
      namespace = "homelab"
      host      = "wled-kitchen.local"
      upstream  = "http://wled-kitchen-external-external-svc.homelab.svc.cluster.local:80"
    }
    "unraid" = {
      name      = "Unraid"
      namespace = "homelab"
      host      = "hoarder.srv"
      upstream  = "http://unraid-external-external-svc.homelab.svc.cluster.local:8080"
    }
    "wallabag" = {
      name      = "Wallabag"
      namespace = "homelab"
      host      = "wallabag"
      upstream  = "http://wallabag.homelab.svc.cluster.local:80"
    }
  }
}

resource "authentik_provider_proxy" "lan" {
  for_each                     = local.lan_proxy_apps
  name                         = "${each.value.name} LAN Proxy"
  mode                         = "proxy"
  external_host                = "https://${each.value.host}.${local.apps_domain}"
  internal_host                = each.value.upstream
  internal_host_ssl_validation = true
  authentication_flow          = authentik_flow.login_choice.uuid
  depends_on                   = [authentik_flow_stage_binding.login_choice]
  authorization_flow           = authentik_flow.provider_consent.uuid
  invalidation_flow            = authentik_flow.provider_logout.uuid
  intercept_header_auth        = true
  skip_path_regex              = try(each.value.skip_path_regex, "")
  access_token_validity        = "hours=1"
  refresh_token_validity       = "hours=8"
  property_mappings = [
    authentik_property_mapping_provider_scope.proxy_outpost.id,
    authentik_property_mapping_provider_scope.oidc_openid.id,
    authentik_property_mapping_provider_scope.oidc_email.id,
    authentik_property_mapping_provider_scope.oidc_profile.id,
    authentik_property_mapping_provider_scope.oidc_entitlements.id,
  ]
}

resource "authentik_application" "lan" {
  for_each           = local.lan_proxy_apps
  name               = each.value.name
  meta_icon          = lookup(local.dashboard_icons, each.key, null)
  slug               = "${each.key}-lan"
  group              = each.value.namespace
  protocol_provider  = authentik_provider_proxy.lan[each.key].id
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "lan_admins" {
  for_each       = local.lan_proxy_apps
  target         = authentik_application.lan[each.key].uuid
  group          = data.sops_file.secrets.data["value_079"]
  order          = 0
  failure_result = false
}

# Upstream charts without a proxy-backend setting delegate standard Ingress
# ownership to the supported Authentik Kubernetes integration.
resource "authentik_outpost" "lan" {
  depends_on = [authentik_policy_binding.lan_admins]

  for_each = toset(["addons", "monitoring", "longhorn-system"])

  name               = "${each.value} LAN Proxy"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.cluster.id
  protocol_providers = [for key, app in local.lan_proxy_apps : authentik_provider_proxy.lan[key].id if app.namespace == each.value]
  config = jsonencode({
    authentik_host                 = data.sops_file.secrets.data["url"]
    authentik_host_insecure        = false
    container_image                = "ghcr.io/goauthentik/proxy:2026.8.5"
    object_naming_template         = "authentik-${each.value}-proxy"
    kubernetes_namespace           = each.value
    kubernetes_replicas            = 1
    kubernetes_service_type        = "ClusterIP"
    kubernetes_ingress_class_name  = "contour"
    kubernetes_ingress_secret_name = "local-wildcard-cert"
    kubernetes_ingress_annotations = {
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
      "projectcontour.io/response-timeout"       = "300s"
      "projectcontour.io/websocket-routes"       = "/"
    }
    kubernetes_disabled_components = concat(
      ["httproute", "traefik middleware", "service-metrics", "prometheus servicemonitor"],
      each.value == "addons" ? ["ingress"] : []
    )
    kubernetes_json_patches = {
      deployment = [{
        op   = "add"
        path = "/spec/template/spec/containers/0/resources"
        value = {
          requests = { cpu = "25m", memory = "64Mi" }
          limits   = { cpu = "500m", memory = "192Mi" }
        }
      }]
    }
  })
}
