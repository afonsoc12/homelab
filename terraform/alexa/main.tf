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

# Authentication is held by the local adapter, outside Terraform and its state.
variable "smapi_endpoint" {
  type      = string
  sensitive = true
  ephemeral = true
}
variable "smapi_session_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "restapi" {
  alias        = "home_assistant_manifest"
  uri          = var.smapi_endpoint
  bearer_token = var.smapi_session_token
  debug        = false
}

resource "restapi_object" "home_assistant_manifest" {
  # Avoid concurrent mutations to the same skill while a build is running.
  depends_on  = [restapi_object.home_assistant_linking]
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
  uri          = var.smapi_endpoint
  bearer_token = var.smapi_session_token
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
  uri          = var.smapi_endpoint
  bearer_token = var.smapi_session_token
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
