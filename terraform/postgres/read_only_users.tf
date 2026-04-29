locals {
  # Read-only roles — get pg_read_all_data, no database ownership
  read_only_users = toset([
    "grafana",
  ])
}

resource "random_password" "read_only" {
  for_each         = local.read_only_users
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+|;:,.<>?"
  keepers = {
    user = each.key
  }
}

resource "postgresql_role" "read_only" {
  for_each = local.read_only_users
  name     = each.key
  login    = true
  password = random_password.read_only[each.key].result
  roles    = ["pg_read_all_data"]
}
