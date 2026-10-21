resource "authentik_event_rule" "notify_configuration_error" {
  destination_event_user = false
  name                   = "Homelab - Notify Configuration Error"
  severity               = "alert"
  transports             = [authentik_event_transport.local_transport.id, authentik_event_transport.email_transport.id]
}

resource "authentik_event_rule" "notify_configuration_warning" {
  destination_event_user = false
  name                   = "Homelab - Notify Configuration Warning"
  severity               = "warning"
  transports             = [authentik_event_transport.local_transport.id, authentik_event_transport.email_transport.id]
}

resource "authentik_event_rule" "notify_exception" {
  destination_event_user = false
  name                   = "Homelab - Notify Exception"
  severity               = "alert"
  transports             = [authentik_event_transport.local_transport.id, authentik_event_transport.email_transport.id]
}

resource "authentik_event_rule" "notify_update" {
  destination_event_user = false
  name                   = "Homelab - Notify Update"
  severity               = "alert"
  transports             = [authentik_event_transport.local_transport.id, authentik_event_transport.email_transport.id]
}

resource "authentik_event_transport" "email_transport" {
  email_subject_prefix = "authentik Notification:"
  email_template       = "email/event_notification.html"
  mode                 = "email"
  name                 = "Homelab - Email Transport"
  send_once            = false
  webhook_url          = ""
}

resource "authentik_event_transport" "local_transport" {
  email_subject_prefix = "authentik Notification:"
  email_template       = "email/event_notification.html"
  mode                 = "local"
  name                 = "Homelab - Local Transport"
  send_once            = false
  webhook_url          = ""
}
