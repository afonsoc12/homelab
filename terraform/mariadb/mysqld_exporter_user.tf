resource "random_password" "mysqld_exporter" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+|;:,.<>?"
  keepers = {
    user = "mysqld_exporter"
  }
}

resource "mysql_user" "mysqld_exporter" {
  user               = "mysqld_exporter"
  host               = "%"
  plaintext_password = random_password.mysqld_exporter.result
}

resource "mysql_grant" "mysqld_exporter" {
  user       = mysql_user.mysqld_exporter.user
  host       = mysql_user.mysqld_exporter.host
  database   = "*"
  privileges = ["PROCESS", "REPLICATION CLIENT", "SELECT"]
}
