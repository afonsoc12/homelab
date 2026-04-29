locals {
  # Add names here — a role and database with the same name is created automatically
  service_databases = toset([
    "airflow",
    "authentik",
    "ghostfolio",
    "mealie",
    "octo_track",
  ])
}

# ----- Passwords -----

resource "random_password" "this" {
  for_each         = local.service_databases
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+|;:,.<>?"
  keepers = {
    user = each.key
  }
}

# ----- Roles (users) -----

resource "postgresql_role" "this" {
  for_each = local.service_databases
  name     = each.key
  login    = true
  password = random_password.this[each.key].result
}

# ----- Databases -----

resource "postgresql_database" "this" {
  for_each = local.service_databases
  name     = each.key
  owner    = postgresql_role.this[each.key].name

  lifecycle {
    prevent_destroy = true
  }
}

# ----- Grants -----

resource "postgresql_grant" "this" {
  for_each    = local.service_databases
  role        = postgresql_role.this[each.key].name
  database    = postgresql_database.this[each.key].name
  object_type = "database"
  privileges  = ["ALL"]
}
