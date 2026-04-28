resource "adguard_list_filter" "hagezi_allowlist_referral" {
  name      = "HaGeZi's Allowlist Referral"
  url       = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt"
  whitelist = true
}
