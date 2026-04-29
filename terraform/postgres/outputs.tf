output "user_passwords" {
  description = "Generated passwords for all managed PostgreSQL roles"
  sensitive   = true
  value = merge(
    { for k, v in random_password.this : k => v.result },
    { for k, v in random_password.read_only : k => v.result },
  )
}
