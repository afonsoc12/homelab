data "sops_file" "settings" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}
locals {
  settings = jsondecode(data.sops_file.settings.data["settings"])
  paths = {
    home_assistant_manifest  = "/v1/skills/${local.settings.skills.home_assistant.id}/stages/development/manifest"
    home_assistant_linking   = "/v1/skills/${local.settings.skills.home_assistant.id}/stages/development/accountLinkingClient"
    music_assistant_manifest = "/v1/skills/${local.settings.skills.music_assistant.id}/stages/development/manifest"
  }
}

# Refresh through the official ASK CLI; never print authentication or API bodies.
data "external" "authentication" {
  program = ["python3", "${path.module}/tools/authenticate.py"]
  query = {
    uri   = local.settings.api_uri
    paths = jsonencode(local.paths)
  }
}

provider "restapi" {
  alias        = "home_assistant_manifest"
  uri          = local.settings.api_uri
  bearer_token = sensitive(data.external.authentication.result.access_token)
  headers      = { "If-Match" = sensitive(data.external.authentication.result.home_assistant_manifest) }
  debug        = false
}

resource "restapi_object" "home_assistant_manifest" {
  provider    = restapi.home_assistant_manifest
  path        = trimsuffix(local.paths.home_assistant_manifest, "/manifest")
  object_id   = "manifest"
  read_path   = local.paths.home_assistant_manifest
  update_path = local.paths.home_assistant_manifest
  data        = jsonencode(local.settings.skills.home_assistant.manifest)
  debug       = false
  lifecycle { prevent_destroy = true }
}

provider "restapi" {
  alias        = "home_assistant_linking"
  uri          = local.settings.api_uri
  bearer_token = sensitive(data.external.authentication.result.access_token)
  headers      = { "If-Match" = sensitive(data.external.authentication.result.home_assistant_linking) }
  debug        = false
}

resource "restapi_object" "home_assistant_linking" {
  provider    = restapi.home_assistant_linking
  path        = trimsuffix(local.paths.home_assistant_linking, "/accountLinkingClient")
  object_id   = "accountLinkingClient"
  read_path   = local.paths.home_assistant_linking
  update_path = local.paths.home_assistant_linking
  data        = jsonencode(local.settings.skills.home_assistant.account_linking)
  # A write-only clientSecret, when required for an update, belongs in the
  # encrypted request override; it cannot be recovered from the read API.
  update_data = jsonencode({ accountLinkingRequest = try(
    local.settings.skills.home_assistant.account_linking_request,
    local.settings.skills.home_assistant.account_linking.accountLinkingResponse
  ) })
  debug = false
  lifecycle { prevent_destroy = true }
}

provider "restapi" {
  alias        = "music_assistant_manifest"
  uri          = local.settings.api_uri
  bearer_token = sensitive(data.external.authentication.result.access_token)
  headers      = { "If-Match" = sensitive(data.external.authentication.result.music_assistant_manifest) }
  debug        = false
}

resource "restapi_object" "music_assistant_manifest" {
  provider    = restapi.music_assistant_manifest
  path        = trimsuffix(local.paths.music_assistant_manifest, "/manifest")
  object_id   = "manifest"
  read_path   = local.paths.music_assistant_manifest
  update_path = local.paths.music_assistant_manifest
  data        = jsonencode(local.settings.skills.music_assistant.manifest)
  debug       = false
  lifecycle { prevent_destroy = true }
}
