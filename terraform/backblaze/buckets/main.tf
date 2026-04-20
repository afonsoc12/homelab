resource "b2_bucket" "this" {
  bucket_name = var.bucket_name
  bucket_type = var.bucket_type

  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 30
  }

  default_server_side_encryption {
    mode      = var.encryption ? "SSE-B2" : "none"
    algorithm = var.encryption ? "AES256" : null
  }

  file_lock_configuration {
    is_file_lock_enabled = var.file_lock
  }

  lifecycle {
    prevent_destroy = true
  }
}
