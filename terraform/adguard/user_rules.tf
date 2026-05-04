resource "adguard_user_rules" "rules" {
  rules = [
    "@@||${data.sops_file.secrets.data["domain"]}^$important",
  ]
}
