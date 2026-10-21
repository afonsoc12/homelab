resource "authentik_group" "administrators" {
  attributes   = data.sops_file.secrets.data["value_006"]
  is_superuser = true
  name         = data.sops_file.secrets.data["value_043"]
  parents      = []
  roles        = []
}

resource "authentik_group" "mealie_admin" {
  attributes   = data.sops_file.secrets.data["value_007"]
  is_superuser = false
  name         = data.sops_file.secrets.data["value_044"]
  parents      = []
  roles        = []
}

resource "authentik_group" "mealie_user" {
  attributes   = data.sops_file.secrets.data["value_008"]
  is_superuser = false
  name         = data.sops_file.secrets.data["value_045"]
  parents      = []
  roles        = []
}
