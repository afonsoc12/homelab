output "user_passwords" {
  description = "Generated passwords for all managed MariaDB users"
  sensitive   = true
  value = merge(
    { for k, v in random_password.this : k => v.result },
    { mysqld_exporter = random_password.mysqld_exporter.result }
  )
}
