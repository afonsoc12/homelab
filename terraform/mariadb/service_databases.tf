locals {
  # Add entries here: name = database name (user with same name is created automatically)
  service_databases = toset([
    "authelia",
    "firefly",
    "wallabag",
    "wedding_site",
  ])

  db_defaults = { charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
}

# ----- Databases -----

resource "mysql_database" "this" {
  for_each              = local.service_databases
  name                  = each.key
  default_character_set = local.db_defaults.charset
  default_collation     = local.db_defaults.collation
}

# ----- Passwords -----

resource "random_password" "this" {
  for_each = local.service_databases
  length   = 20
  special  = true
  # exclude chars that break connection strings or shell quoting
  override_special = "!#$%^&*()-_=+|;:,.<>?"
  keepers = {
    user = each.key
  }
}

# ----- Users -----

resource "mysql_user" "this" {
  for_each           = local.service_databases
  user               = each.key
  host               = "%"
  plaintext_password = random_password.this[each.key].result
}

# ----- Grants -----

resource "mysql_grant" "this" {
  for_each   = local.service_databases
  user       = mysql_user.this[each.key].user
  host       = mysql_user.this[each.key].host
  database   = mysql_database.this[each.key].name
  privileges = ["ALL PRIVILEGES"]
}
