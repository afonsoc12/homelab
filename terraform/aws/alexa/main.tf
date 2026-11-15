terraform {
  required_providers {
    restful = {
      source                = "magodo/restful"
      version               = "= 0.25.2"
      configuration_aliases = [restful.home_assistant, restful.music_assistant, restful.account_linking]
    }
  }
}
variable "settings" {
  type      = any
  sensitive = true
}
resource "restful_resource" "home_assistant" {
  provider             = restful.home_assistant
  path                 = "/v1/skills/${var.settings.skills.home_assistant.id}/stages/development/manifest"
  body                 = var.settings.skills.home_assistant.manifest
  create_method        = "PUT"
  update_method        = "PUT"
  use_sensitive_output = true
  poll_update = {
    header            = { "Accept" = "application/json" }
    url_locator       = "exact.${var.settings.api_uri}/v1/skills/${var.settings.skills.home_assistant.id}/status?resource=manifest"
    status_locator    = "body.manifest.lastUpdateRequest.status"
    status            = { success = "SUCCEEDED", pending = ["IN_PROGRESS"] }
    default_delay_sec = 2
  }
  lifecycle { prevent_destroy = true }
}
resource "restful_resource" "music_assistant" {
  provider             = restful.music_assistant
  path                 = "/v1/skills/${var.settings.skills.music_assistant.id}/stages/development/manifest"
  body                 = var.settings.skills.music_assistant.manifest
  create_method        = "PUT"
  update_method        = "PUT"
  use_sensitive_output = true
  poll_update = {
    header            = { "Accept" = "application/json" }
    url_locator       = "exact.${var.settings.api_uri}/v1/skills/${var.settings.skills.music_assistant.id}/status?resource=manifest"
    status_locator    = "body.manifest.lastUpdateRequest.status"
    status            = { success = "SUCCEEDED", pending = ["IN_PROGRESS"] }
    default_delay_sec = 2
  }
  lifecycle { prevent_destroy = true }
}
resource "restful_resource" "account_linking" {
  provider               = restful.account_linking
  path                   = "/v1/skills/${var.settings.skills.home_assistant.id}/stages/development/accountLinkingClient"
  body                   = { accountLinkingRequest = var.settings.skills.home_assistant.account_linking.accountLinkingResponse }
  read_response_template = <<-JSON
  {"accountLinkingRequest":$(body.accountLinkingResponse)}
  JSON
  create_method          = "PUT"
  update_method          = "PUT"
  use_sensitive_output   = true
  lifecycle { prevent_destroy = true }
}
