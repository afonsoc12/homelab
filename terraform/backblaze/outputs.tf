output "bucket_ids" {
  value = { for k, v in module.buckets : k => v.bucket_id }
}

output "bucket_names" {
  value     = { for k, v in module.buckets : k => v.bucket_name }
  sensitive = true
}

output "longhorn_key_id" {
  value = b2_application_key.longhorn.application_key_id
}

output "velero_key_id" {
  value = b2_application_key.velero.application_key_id
}

output "longhorn_application_key" {
  value     = b2_application_key.longhorn.application_key
  sensitive = true
}

output "velero_application_key" {
  value     = b2_application_key.velero.application_key
  sensitive = true
}
