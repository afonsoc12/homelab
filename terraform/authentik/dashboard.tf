locals {
  # Keep authentication integrations intact; expose one service launcher.
  dashboard_native_apps = toset(["airflow", "bambuddy", "booklore", "freshrss", "home-assistant", "node-red", "paperless", "wireguard"])
  dashboard_service_names = {
    airflow   = "Airflow"
    bambuddy  = "Bambuddy"
    booklore  = "BookLore"
    freshrss  = "FreshRSS"
    paperless = "Paperless"
  }
}
