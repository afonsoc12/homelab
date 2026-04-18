data "sops_file" "records" {
  source_file = var.records_file
  input_type  = "yaml"
}

locals {
  all_records = yamldecode(data.sops_file.records.raw).records
  static      = [for r in local.all_records : r if !try(r.dynamic, false)]
  dynamic     = [for r in local.all_records : r if try(r.dynamic, false)]
}

resource "cloudflare_dns_record" "static" {
  for_each = nonsensitive({
    for r in local.static : "${r.name}|${r.type}|${try(r.index, 0)}" => r
  })

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = try(each.value.ttl, 1)
}

resource "cloudflare_dns_record" "dynamic" {
  for_each = nonsensitive({
    for r in local.dynamic : "${r.name}|${r.type}|${try(r.index, 0)}" => r
  })

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = try(each.value.ttl, 1)

  lifecycle {
    ignore_changes = [content]
  }
}
