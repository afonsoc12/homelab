resource "adguard_user_rules" "rules" {
  rules = []

  lifecycle {
    ignore_changes = [last_updated]
  }
}
