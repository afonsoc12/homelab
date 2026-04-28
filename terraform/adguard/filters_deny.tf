# ==================== General ====================

resource "adguard_list_filter" "hosts_1_lite" {
  name = "1Hosts (Lite)"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt"
}

# resource "adguard_list_filter" "hosts_1_pro" {
#   name = "1Hosts (Pro)"
#   url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_64.txt"
# }

resource "adguard_list_filter" "adguard_dns_filter" {
  name = "AdGuard DNS filter"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
}

resource "adguard_list_filter" "adguard_popup_filter" {
  name = "AdGuard DNS Popup Hosts filter"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt"
}

resource "adguard_list_filter" "awavenue_ads_rule" {
  name = "AWAvenue Ads Rule"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt"
}

resource "adguard_list_filter" "dan_pollocks_list" {
  name = "Dan Pollock's List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt"
}

resource "adguard_list_filter" "hagezi_normal" {
  name = "HaGeZi's Normal Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_34.txt"
}

resource "adguard_list_filter" "hagezi_pro" {
  name = "HaGeZi's Pro Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_48.txt"
}

resource "adguard_list_filter" "oisd_small" {
  name = "OISD Blocklist Small"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_5.txt"
}

resource "adguard_list_filter" "oisd_big" {
  name = "OISD Blocklist Big"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt"
}

resource "adguard_list_filter" "peter_lowe_list" {
  name = "Peter Lowe's Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt"
}

resource "adguard_list_filter" "steven_blacks_list" {
  name = "Steven Black's List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt"
}

# ==================== Other ====================

resource "adguard_list_filter" "dandelion_sprouts_anti_push_notifications" {
  name = "Dandelion Sprout's Anti Push Notifications"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt"
}

resource "adguard_list_filter" "dandelion_sprouts_game_console_adblock" {
  name = "Dandelion Sprout's Game Console Adblock List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt"
}

resource "adguard_list_filter" "hagezi_apple_tracker" {
  name = "HaGeZi's Apple Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_67.txt"
}

resource "adguard_list_filter" "hagezi_gambling" {
  name = "HaGeZi's Gambling Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt"
}

resource "adguard_list_filter" "hagezi_oppo_realme_tracker" {
  name = "HaGeZi's OPPO & Realme Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_66.txt"
}

resource "adguard_list_filter" "hagezi_samsung_tracker" {
  name = "HaGeZi's Samsung Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_61.txt"
}

resource "adguard_list_filter" "hagezi_vivo_tracker" {
  name = "HaGeZi's Vivo Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_65.txt"
}

resource "adguard_list_filter" "hagezi_windows_office_tracker" {
  name = "HaGeZi's Windows/Office Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt"
}

resource "adguard_list_filter" "hagezi_xiaomi_tracker" {
  name = "HaGeZi's Xiaomi Tracker Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_60.txt"
}

resource "adguard_list_filter" "smart_tv_blocklist" {
  name = "Perflyst and Dandelion Sprout's Smart-TV Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt"
}

resource "adguard_list_filter" "shadowwhisperers_dating" {
  name = "ShadowWhisperer's Dating List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_57.txt"
}

resource "adguard_list_filter" "shadowwhisperer_tracking" {
  name = "ShadowWhisperer Tracking List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_69.txt"
}

resource "adguard_list_filter" "ukrainian_security_filter" {
  name = "Ukrainian Security Filter"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_62.txt"
}

# ==================== Regional ====================

resource "adguard_list_filter" "chn_adrules" {
  name = "CHN: AdRules DNS List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_29.txt"
}

resource "adguard_list_filter" "chn_anti_ad" {
  name = "CHN: anti-AD"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_21.txt"
}

resource "adguard_list_filter" "isr_easylist_hebrew" {
  name = "ISR: EasyList Hebrew"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_43.txt"
}

resource "adguard_list_filter" "pol_cert_polska" {
  name = "POL: CERT Polska List of malicious domains"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_41.txt"
}

resource "adguard_list_filter" "pol_polish_filters" {
  name = "POL: Polish filters for Pi-hole"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_14.txt"
}

resource "adguard_list_filter" "tur_turk_adlist" {
  name = "TUR: turk-adlist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_26.txt"
}

resource "adguard_list_filter" "tur_turkish_ad_hosts" {
  name = "TUR: Turkish Ad Hosts"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_40.txt"
}

resource "adguard_list_filter" "vnm_abpvn" {
  name = "VNM: ABPVN List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_16.txt"
}

# ==================== Security ====================

resource "adguard_list_filter" "big_list_hacked_malware" {
  name = "The Big List of Hacked Malware Web Sites"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
}

resource "adguard_list_filter" "malicious_url_blocklist_urlhaus" {
  name = "Malicious URL Blocklist (URLHaus)"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
}

resource "adguard_list_filter" "phishing_url_blocklist" {
  name = "Phishing URL Blocklist (PhishTank and OpenPhish)"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt"
}

resource "adguard_list_filter" "dandelion_sprouts_anti_malware" {
  name = "Dandelion Sprout's Anti-Malware List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt"
}

resource "adguard_list_filter" "hagezi_badware_hoster" {
  name = "HaGeZi's Badware Hoster Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt"
}

resource "adguard_list_filter" "hagezi_dyndns" {
  name = "HaGeZi's DynDNS Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt"
}

resource "adguard_list_filter" "hagezi_threat_intelligence" {
  name = "HaGeZi's Threat Intelligence Feeds"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt"
}

resource "adguard_list_filter" "hagezi_url_shortener" {
  name = "HaGeZi's URL Shortener Blocklist"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_68.txt"
}

resource "adguard_list_filter" "nocoin_filter" {
  name = "NoCoin Filter List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt"
}

resource "adguard_list_filter" "phishing_army" {
  name = "Phishing Army"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt"
}

resource "adguard_list_filter" "scam_blocklist_durablenapkin" {
  name = "Scam Blocklist by DurableNapkin"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt"
}

resource "adguard_list_filter" "shadowwhisperers_malware" {
  name = "ShadowWhisperer's Malware List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt"
}

resource "adguard_list_filter" "stalkerware_indicators" {
  name = "Stalkerware Indicators List"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt"
}

resource "adguard_list_filter" "ublock_badware_risks" {
  name = "uBlock₀ filters – Badware risks"
  url  = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt"
}
